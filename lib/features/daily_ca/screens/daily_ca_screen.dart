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
import '../daily_ca_admin_constants.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_day_sheet.dart';
import '../widgets/daily_ca_month_calendar.dart';
import '../widgets/daily_ca_today_section.dart';
import '../widgets/daily_ca_yesterday_leaderboard_hero.dart';
import '../../home/domain/daily_rituals.dart';

class DailyCaScreen extends HookConsumerWidget {
  const DailyCaScreen({super.key, this.autoStartPaper = false});

  /// Set from the morning notification tap so it lands on the quiz itself.
  final bool autoStartPaper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minDate = ref
        .watch(dailyCaCalendarMinDateProvider)
        .maybeWhen(
          data: (date) => date,
          orElse: () => DailyCaSchedule.defaultCalendarMinDate,
        );
    final minMonth = DailyCaSchedule.minMonthForDate(minDate);
    final istNow = DailyCaSchedule.nowIst();
    final paperDate = DailyCaSchedule.expectedPaperContentDate(
      referenceIst: istNow,
    );
    final paperOpen = DailyCaSchedule.isPublishedForDate(
      paperDate,
      referenceIst: istNow,
    );
    final paperIso = DailyCaSchedule.formatIsoDate(paperDate);
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

    useEffect(() {
      unawaited(markDailyRitualOpened(ref, DailyRitualIds.dailyCa));
      return null;
    }, const []);

    final paperCompleted = completedAsync.maybeWhen(
      data: (dates) => dates.contains(paperIso),
      orElse: () => false,
    );
    final ranksOn =
        ref.watch(dailyCaRanksRemoteEnabledProvider).asData?.value ?? false;

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
      final sessionId = await db.sessionsDao.getLatestCompletedDailyCaSessionId(
        isoDate,
      );
      if (!context.mounted) return;
      if (sessionId == null) {
        await openDayTest(isoDate, isRevise: true);
        return;
      }
      final ranksOn =
          ref.read(dailyCaRanksRemoteEnabledProvider).asData?.value ?? false;
      context.push(
        ranksOn ? dailyCaResultsRoute(sessionId) : '/results/$sessionId',
      );
    }

    final openDayTestStable = useCallback(openDayTest, [
      monthKey,
      paperCompleted,
    ]);

    final autoStarted = useRef(false);
    useEffect(() {
      if (!autoStartPaper || autoStarted.value) return null;
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.md : AppSpacing.lg,
          compact ? AppSpacing.sm : AppSpacing.md,
          compact ? AppSpacing.md : AppSpacing.lg,
          paddedBottomInset(context, compact ? AppSpacing.sm : AppSpacing.md),
        ),
        children: [
          DailyCaYesterdayLeaderboardHero(compact: compact),
          DailyCaTodaySection(
            minDate: minDate,
            paperDate: paperDate,
            paperCompleted: paperCompleted,
            launching: launching.value || paperChecking,
            paperOpen: paperOpen,
            questionsReady: paperLive,
            compact: compact,
            onStartPaper: paperCompleted || !paperLive
                ? null
                : () => unawaited(openDayTest(paperIso, isRevise: false)),
            onRevisePaper: !paperCompleted
                ? null
                : () => unawaited(openDayTest(paperIso, isRevise: true)),
            onViewResults: !paperCompleted
                ? null
                : () => unawaited(openPaperResults(paperIso)),
            onViewRankings: null,
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          DecoratedBox(
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
                mainAxisSize: MainAxisSize.min,
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
                  completedAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        final now = DailyCaSchedule.nowIst();
                        if (!DailyCaSchedule.isCalendarDaySelectable(
                          date,
                          minDate: minDate,
                          referenceIst: now,
                        )) {
                          return;
                        }
                        final contentDate =
                            DailyCaSchedule.calendarTapContentDate(
                              date,
                              referenceIst: now,
                            );
                        if (contentDate == null ||
                            !DailyCaSchedule.isOnOrAfterMinDate(
                              contentDate,
                              minDate,
                            )) {
                          return;
                        }
                        final contentIso = DailyCaSchedule.formatIsoDate(
                          contentDate,
                        );
                        final isTodayTap =
                            DailyCaSchedule.dateOnly(date) ==
                            DailyCaSchedule.dateOnly(now);
                        unawaited(
                          showDailyCaDaySheet(
                            context: context,
                            isoDate: contentIso,
                            completed: completed.contains(contentIso),
                            questionsReady: !isTodayTap || paperLive,
                            onStartTest: () => unawaited(
                              openDayTest(
                                contentIso,
                                isRevise: completed.contains(contentIso),
                              ),
                            ),
                            onViewRankings:
                                !ranksOn || contentIso == paperIso
                                ? null
                                : () => context.push(
                                    dailyCaLeaderboardRoute(contentIso),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
