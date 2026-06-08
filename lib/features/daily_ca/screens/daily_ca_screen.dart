import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../data/daily_ca_repository.dart';
import '../domain/daily_ca_schedule.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_month_calendar.dart';

class DailyCaScreen extends HookConsumerWidget {
  const DailyCaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final nowIst = useState(DailyCaSchedule.nowIst());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        nowIst.value = DailyCaSchedule.nowIst();
      });
      return timer.cancel;
    }, const []);

    final ist = nowIst.value;
    final todayIso = DailyCaSchedule.formatIsoDate(ist);
    final displayedMonth = useState(DateTime(ist.year, ist.month));
    final monthKey = DailyCaMonthKey(
      year: displayedMonth.value.year,
      month: displayedMonth.value.month,
    );
    final completedAsync = ref.watch(dailyCaCompletedDatesProvider(monthKey));
    final launching = useState(false);

    final todayPublished = DailyCaSchedule.isPublishedForDate(ist);
    final todayIsTestDay = DailyCaSchedule.isTestDay(ist);
    final countdown = DailyCaSchedule.timeUntilNextPublish(referenceIst: ist);
    final countdownLabel = DailyCaSchedule.formatCountdown(countdown);
    final todayCompleted = completedAsync.maybeWhen(
      data: (dates) => dates.contains(todayIso),
      orElse: () => false,
    );

    Future<void> openDayTest(String isoDate, {required bool isRevise}) async {
      if (launching.value) return;
      launching.value = true;
      try {
        final repo = ref.read(dailyCaRepositoryProvider);
        final uuids = await repo.ensureCachedForDate(isoDate);
        if (!context.mounted) return;
        final parsed = DailyCaSchedule.parseIsoDate(isoDate);
        final label = DateFormat('d MMM yyyy').format(parsed);

        await showTestConfigBottomSheet(
          context: context,
          args: TestConfigSheetArgs(
            subject: QuestionSourceConstants.dailyCaSessionSubject,
            topic: isoDate,
            subjectDisplayName: 'Daily Current Affairs',
            topicDisplayName: label,
            availableQuestionCount: uuids.length,
            topicCountWhenSubjectOnly: 1,
            lockedQuestionCount: uuids.length,
            specificQuestionUuids: uuids,
            fixedQuestionSetLabel: '${uuids.length} questions · $label',
            startButtonLabel: isRevise ? 'Revise' : 'Start test',
            analyticsFeatureKey: isRevise
                ? '${QuestionSourceConstants.analyticsDailyCurrentAffairs}_revise'
                : QuestionSourceConstants.analyticsDailyCurrentAffairs,
            onSessionCreated: (sessionId) async {
              await context.push('/test/$sessionId');
              if (context.mounted) {
                ref.invalidate(dailyCaCompletedDatesProvider(monthKey));
                ref.invalidate(dailyCaDayCompletedProvider(isoDate));
              }
            },
          ),
        );
      } on DailyCaNotAvailableException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Questions for this date are not available yet.',
                style: AppTextStyles.bodySm(),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not load test. Check your connection and try again.',
                style: AppTextStyles.bodySm(),
              ),
            ),
          );
        }
      } finally {
        launching.value = false;
      }
    }

    void shiftMonth(int delta) {
      final m = displayedMonth.value;
      displayedMonth.value = DateTime(m.year, m.month + delta);
    }

    final monthTitle = DateFormat('MMMM yyyy').format(displayedMonth.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Current Affairs')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "TODAY'S TEST",
                  style: AppTextStyles.caption().copyWith(
                    color: isDark ? AppColors.infoTextDark : AppColors.infoText,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!todayIsTestDay)
                  Text(
                    'Sundays are rest days — no test today.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else if (!todayPublished)
                  Text(
                    'Available at 9:00 PM IST · $countdownLabel remaining',
                    style: AppTextStyles.body().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    todayCompleted
                        ? 'Completed · tap to revise'
                        : "10 MCQs from today's news",
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: (!todayIsTestDay ||
                          !todayPublished ||
                          launching.value)
                      ? null
                      : () => openDayTest(
                            todayIso,
                            isRevise: todayCompleted,
                          ),
                  icon: launching.value
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Icon(
                          todayCompleted
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                        ),
                  label: Text(
                    !todayIsTestDay
                        ? 'No test today'
                        : !todayPublished
                        ? 'Opens at 9 PM'
                        : todayCompleted
                        ? "Revise today's test"
                        : "Start today's test",
                  ),
                ),
                if (todayIsTestDay && !todayPublished) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Next test in $countdownLabel',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              IconButton(
                onPressed: () => shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
              ),
              IconButton(
                onPressed: () => shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap a date to open that day\'s test. Sundays are off.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          completedAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(
              'Could not load progress: $e',
              style: AppTextStyles.bodySm().copyWith(color: AppColors.wrong),
            ),
            data: (completed) => DailyCaMonthCalendar(
              year: displayedMonth.value.year,
              month: displayedMonth.value.month,
              completedDates: completed,
              nowIst: ist,
              onDateTap: (iso) {
                final date = DailyCaSchedule.parseIsoDate(iso);
                if (!DailyCaSchedule.isPublishedForDate(date, referenceIst: ist)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This test is not available yet.',
                        style: AppTextStyles.bodySm(),
                      ),
                    ),
                  );
                  return;
                }
                unawaited(
                  openDayTest(iso, isRevise: completed.contains(iso)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
