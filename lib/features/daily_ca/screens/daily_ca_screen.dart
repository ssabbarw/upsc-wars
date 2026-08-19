import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/notifications/notification_prompt_policy.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';
import '../domain/open_daily_ca_test.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_day_sheet.dart';
import '../widgets/daily_ca_month_calendar.dart';
import '../widgets/daily_ca_today_section.dart';

class DailyCaScreen extends HookConsumerWidget {
  const DailyCaScreen({super.key, this.autoStartPaper = false});

  /// Set from the morning notification tap so it lands on the quiz itself.
  final bool autoStartPaper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minDate = ref.watch(dailyCaCalendarMinDateProvider).maybeWhen(
      data: (date) => date,
      orElse: () => DailyCaSchedule.defaultCalendarMinDate,
    );
    final minMonth = DailyCaSchedule.minMonthForDate(minDate);
    final istNow = DailyCaSchedule.nowIst();
    final paperDate = DailyCaSchedule.paperQuizContentDate(referenceIst: istNow);
    final paperIso =
        paperDate == null ? null : DailyCaSchedule.formatIsoDate(paperDate);
    final paperLiveAsync = ref.watch(dailyCaScheduledPaperIsLiveProvider);
    final paperLive = paperLiveAsync.asData?.value ?? false;
    final paperChecking = paperLiveAsync.isLoading;
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
    final compact = MediaQuery.sizeOf(context).height < 760;

    final paperCompleted = paperIso != null &&
        completedAsync.maybeWhen(
          data: (dates) => dates.contains(paperIso),
          orElse: () => false,
        );

    Future<void> openDayTest(String isoDate, {required bool isRevise}) async {
      if (launching.value) return;
      launching.value = true;
      try {
        await openDailyCaTest(
          context: context,
          ref: ref,
          isoDate: isoDate,
          isRevise: isRevise,
          onFinished: () =>
              ref.invalidate(dailyCaCompletedDatesProvider(monthKey)),
        );
      } finally {
        launching.value = false;
      }
    }

    Future<void> openPaperResults(String isoDate) async {
      final db = ref.read(userDatabaseProvider);
      final sessionId =
          await db.sessionsDao.getLatestCompletedDailyCaSessionId(isoDate);
      if (!context.mounted) return;
      if (sessionId == null) {
        await openDayTest(isoDate, isRevise: true);
        return;
      }
      context.push('/results/$sessionId');
    }

    final openDayTestStable = useCallback(
      openDayTest,
      [monthKey, paperCompleted],
    );

    final autoStarted = useRef(false);
    useEffect(() {
      if (!autoStartPaper || autoStarted.value || paperIso == null) return null;
      if (paperChecking) return null;
      autoStarted.value = true;
      if (!paperLive) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(openDayTestStable(paperIso, isRevise: paperCompleted));
      });
      return null;
    }, [autoStartPaper, paperIso, paperLive, paperChecking]);

    useEffect(() {
      if (autoStartPaper) return null;
      unawaited(
        BattleMessagingService.maybePromptAfterScreenSettles(
          context: context,
          surface: NotificationPromptSurface.dailyCa,
          source: 'daily_ca_screen',
        ),
      );
      return null;
    }, const []);

    void shiftMonth(int delta) {
      final m = displayedMonth.value;
      final next = DateTime(m.year, m.month + delta);
      final maxMonth = DateTime(istNow.year, istNow.month);
      if (delta < 0 &&
          DailyCaSchedule.isMonthBefore(next.year, next.month, minMonth)) {
        return;
      }
      if (delta > 0 &&
          DailyCaSchedule.isMonthAfter(next.year, next.month, maxMonth)) {
        return;
      }
      displayedMonth.value = next;
    }

    void jumpToThisMonth() {
      displayedMonth.value = DateTime(istNow.year, istNow.month);
    }

    final canGoToPreviousMonth = !DailyCaSchedule.isMonthBefore(
      displayedMonth.value.year,
      displayedMonth.value.month - 1,
      minMonth,
    );
    final maxMonth = DateTime(istNow.year, istNow.month);
    final canGoToNextMonth = !DailyCaSchedule.isMonthAfter(
      displayedMonth.value.year,
      displayedMonth.value.month + 1,
      maxMonth,
    );
    final monthTitle = DateFormat('MMMM yyyy').format(displayedMonth.value);
    final cardShadow = [
      BoxShadow(
        color: AppColors.gray900.withValues(alpha: isDark ? 0.35 : 0.07),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceTertiaryDark
          : AppColors.surfaceTertiaryLight,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Daily Current Affairs'),
        actions: [
          IconButton(
            tooltip: 'This month',
            onPressed: jumpToThisMonth,
            icon: const Icon(
              Icons.event_available_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.md : AppSpacing.lg,
          compact ? AppSpacing.sm : AppSpacing.md,
          compact ? AppSpacing.md : AppSpacing.lg,
          paddedBottomInset(context, compact ? AppSpacing.sm : AppSpacing.md),
        ),
        child: Column(
          children: [
            DailyCaTodaySection(
              minDate: minDate,
              paperDate: paperDate,
              paperCompleted: paperCompleted,
              launching: launching.value || paperChecking,
              questionsReady: paperLive,
              compact: compact,
              onStartPaper: paperIso == null
                  ? null
                  : paperCompleted
                  ? () => unawaited(openPaperResults(paperIso))
                  : paperLive
                  ? () => unawaited(openDayTest(paperIso, isRevise: false))
                  : null,
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: cardShadow,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    compact ? AppSpacing.sm : AppSpacing.md,
                    AppSpacing.md,
                    compact ? AppSpacing.sm : AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'HISTORY',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Row(
                        children: [
                          _MonthNavButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: canGoToPreviousMonth
                                ? () => shiftMonth(-1)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              monthTitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h3().copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _MonthNavButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: canGoToNextMonth
                                ? () => shiftMonth(1)
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Expanded(
                        child: completedAsync.when(
                          loading: () => const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (e, _) => Center(
                            child: Text(
                              'Could not load progress: $e',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySm().copyWith(
                                color: AppColors.wrong,
                              ),
                            ),
                          ),
                          data: (completed) => DailyCaMonthCalendar(
                            year: displayedMonth.value.year,
                            month: displayedMonth.value.month,
                            completedDates: completed,
                            minDate: minDate,
                            paperIso: paperIso,
                            onDateTap: (iso) {
                              if (launching.value) return;
                              final date = DailyCaSchedule.parseIsoDate(iso);
                              if (!DailyCaSchedule.isOnOrAfterMinDate(
                                date,
                                minDate,
                              )) {
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
                                showDailyCaDaySheet(
                                  context: context,
                                  isoDate: iso,
                                  completed: completed.contains(iso),
                                  onStartTest: () => unawaited(
                                    openDayTest(
                                      iso,
                                      isRevise: completed.contains(iso),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}
