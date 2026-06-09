import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../data/daily_ca_firestore.dart';
import '../data/daily_ca_load_error.dart';
import '../data/daily_ca_repository.dart';
import '../domain/daily_ca_schedule.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_month_calendar.dart';
import '../widgets/daily_ca_today_section.dart';

class DailyCaScreen extends HookConsumerWidget {
  const DailyCaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final minDate = ref.watch(dailyCaCalendarMinDateProvider).maybeWhen(
      data: (date) => date,
      orElse: () => DailyCaSchedule.defaultCalendarMinDate,
    );
    final minMonth = DailyCaSchedule.minMonthForDate(minDate);
    final istNow = DailyCaSchedule.nowIst();
    final todayIso = DailyCaSchedule.formatIsoDate(istNow);
    final initialMonth = DateTime(istNow.year, istNow.month);
    final displayedMonth = useState(
      initialMonth.isBefore(minMonth) ? minMonth : initialMonth,
    );
    final monthKey = DailyCaMonthKey(
      year: displayedMonth.value.year,
      month: displayedMonth.value.month,
    );
    final completedAsync = ref.watch(dailyCaCompletedDatesProvider(monthKey));
    final launching = useState(false);

    final todayCompleted = completedAsync.maybeWhen(
      data: (dates) => dates.contains(todayIso),
      orElse: () => false,
    );

    Future<void> openDayTest(String isoDate, {required bool isRevise}) async {
      if (launching.value) return;
      launching.value = true;
      final firestorePath = DailyCaFirestore.pathForDate(isoDate);
      try {
        debugPrint('[DailyCaScreen] Loading $isoDate from $firestorePath');
        final repo = ref.read(dailyCaRepositoryProvider);
        final uuids = await repo.ensureCachedForDate(isoDate);
        if (!context.mounted) return;
        if (uuids.isEmpty) {
          throw DailyCaNotAvailableException(isoDate, firestorePath: firestorePath);
        }

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
      } catch (e, st) {
        final message = dailyCaLoadErrorMessage(e);
        developer.log(
          'Daily CA load failed for $isoDate ($firestorePath): $message',
          name: 'DailyCaScreen',
          stackTrace: st,
        );
        debugPrint('[DailyCaScreen] $message');
        debugPrintStack(stackTrace: st, label: 'DailyCaScreen');

        if (!context.mounted) return;
        final snackText = kDebugMode
            ? message
            : dailyCaErrorIsPermissionDenied(e)
            ? 'Firestore access denied. Deploy latest firestore.rules, then retry.'
            : dailyCaErrorIsNotAvailable(e)
            ? 'Questions for this date are not available yet.'
            : 'Could not load test. Check your connection and try again.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              snackText,
              style: AppTextStyles.bodySm(),
            ),
          ),
        );
      } finally {
        launching.value = false;
      }
    }

    final openDayTestStable = useCallback(
      openDayTest,
      [monthKey, todayCompleted],
    );

    void shiftMonth(int delta) {
      final m = displayedMonth.value;
      final next = DateTime(m.year, m.month + delta);
      if (delta < 0 &&
          DailyCaSchedule.isMonthBefore(next.year, next.month, minMonth)) {
        return;
      }
      displayedMonth.value = next;
    }

    final canGoToPreviousMonth = !DailyCaSchedule.isMonthBefore(
      displayedMonth.value.year,
      displayedMonth.value.month - 1,
      minMonth,
    );
    final minDateLabel = DateFormat('d MMM yyyy').format(minDate);
    final monthTitle = DateFormat('MMMM yyyy').format(displayedMonth.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Current Affairs')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DailyCaTodaySection(
            minDate: minDate,
            todayCompleted: todayCompleted,
            launching: launching.value,
            onStartToday: () => unawaited(
              openDayTestStable(todayIso, isRevise: todayCompleted),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              IconButton(
                onPressed: canGoToPreviousMonth ? () => shiftMonth(-1) : null,
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
            'Tap a date from $minDateLabel onward. Sundays are off.',
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
              minDate: minDate,
              onDateTap: (iso) {
                if (launching.value) return;
                final date = DailyCaSchedule.parseIsoDate(iso);
                if (!DailyCaSchedule.isOnOrAfterMinDate(date, minDate)) {
                  return;
                }
                final now = DailyCaSchedule.nowIst();
                if (!DailyCaSchedule.isPublishedForDate(
                  date,
                  referenceIst: now,
                )) {
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
                  openDayTestStable(iso, isRevise: completed.contains(iso)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
