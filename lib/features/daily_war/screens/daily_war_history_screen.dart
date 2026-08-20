import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/notifications/notification_prompt_policy.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/start_daily_war_attempt.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../widgets/daily_war_earned_badges_section.dart';
import '../widgets/daily_war_month_calendar.dart';
import '../widgets/daily_war_today_section.dart';
import 'daily_war_history_detail_screen.dart';

/// Calendar hub for Daily War — tonight's paper on top, archive by date.
class DailyWarHistoryScreen extends HookConsumerWidget {
  const DailyWarHistoryScreen({super.key, this.embedded = false});

  /// When true, omit [Scaffold] / [AppBar] (used inside Progress hub).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(dailyWarHistoryBundleProvider);
    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final launching = useState(false);

    final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
    final tick = useState(0);
    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      return t.cancel;
    }, const []);
    tick.value;

    useEffect(() {
      if (embedded) return null;
      unawaited(
        BattleMessagingService.maybePromptAfterScreenSettles(
          context: context,
          surface: NotificationPromptSurface.dailyWar,
          source: 'daily_war_history',
        ),
      );
      return null;
    }, const []);

    final ist = DailyWarSchedule.nowIst(
      DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch + offset,
        isUtc: true,
      ),
    );
    final todayIso = DailyWarSchedule.formatIsoDate(
      DailyWarSchedule.warDateFor(ist),
    );
    final minDate = DailyWarSchedule.dateOnly(DailyWarSchedule.calendarMinDate);

    final initialMonth = DateTime(ist.year, ist.month);
    final displayedMonth = useState(initialMonth);
    final monthTitle = DateFormat('MMMM yyyy').format(displayedMonth.value);

    final live = snap.phase == DailyWarPhase.liveJoinable;
    final inLobby = snap.phase == DailyWarPhase.lobby;

    Future<void> joinLive() async {
      if (inLobby) {
        if (context.mounted) context.push(dailyWarLobbyRoute());
        return;
      }
      final doc = snap.doc;
      if (doc == null || launching.value) {
        if (doc == null && context.mounted) {
          context.push(dailyWarLobbyRoute());
        }
        return;
      }
      launching.value = true;
      try {
        await startDailyWarAttempt(
          context: context,
          ref: ref,
          doc: doc,
          unranked: false,
          istNow: ist,
        );
      } finally {
        launching.value = false;
      }
    }

    Future<void> attemptUnranked(DailyWarDoc doc) async {
      if (launching.value) return;
      launching.value = true;
      try {
        await startDailyWarAttempt(
          context: context,
          ref: ref,
          doc: doc,
          unranked: true,
          istNow: ist,
        );
      } finally {
        launching.value = false;
      }
    }

    Future<void> onTodayUnranked() async {
      final doc = snap.doc;
      if (doc == null) {
        if (context.mounted) context.push(dailyWarLobbyRoute());
        return;
      }
      await attemptUnranked(doc);
    }

    void shiftMonth(int delta) {
      final m = displayedMonth.value;
      final next = DateTime(m.year, m.month + delta);
      final minMonth = DateTime(minDate.year, minDate.month);
      final maxMonth = DateTime(ist.year, ist.month);
      if (delta < 0 &&
          (next.year < minMonth.year ||
              (next.year == minMonth.year && next.month < minMonth.month))) {
        return;
      }
      if (delta > 0 &&
          (next.year > maxMonth.year ||
              (next.year == maxMonth.year && next.month > maxMonth.month))) {
        return;
      }
      displayedMonth.value = next;
    }

    void jumpToThisMonth() {
      displayedMonth.value = DateTime(ist.year, ist.month);
    }

    Future<void> onDateTap(String iso) async {
      final date = DailyWarSchedule.parseIsoDate(iso);
      if (DailyWarSchedule.isWarOffDay(date)) return;
      if (date.isBefore(minDate)) return;
      if (date.isAfter(DailyWarSchedule.dateOnly(ist))) return;
      if (!context.mounted) return;
      await showDailyWarDaySheet(context: context, dateId: iso);
    }

    final minMonth = DateTime(minDate.year, minDate.month);
    final maxMonth = DateTime(ist.year, ist.month);
    final shownMonth = DateTime(
      displayedMonth.value.year,
      displayedMonth.value.month,
    );
    final canGoToPreviousMonth =
        shownMonth.year > minMonth.year ||
        (shownMonth.year == minMonth.year && shownMonth.month > minMonth.month);
    final canGoToNextMonth =
        shownMonth.year < maxMonth.year ||
        (shownMonth.year == maxMonth.year && shownMonth.month < maxMonth.month);

    final cardShadow = [
      BoxShadow(
        color: AppColors.gray900.withValues(alpha: isDark ? 0.35 : 0.07),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

    final body = ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        paddedBottomInset(context, AppSpacing.lg),
      ),
      children: [
        DailyWarTodaySection(
          launching: launching.value,
          onJoinLive: () => unawaited(joinLive()),
          onOpenResults: () {
            if (snap.dateId.isEmpty) return;
            unawaited(
              showDailyWarDaySheet(context: context, dateId: snap.dateId),
            );
          },
          onAttemptUnranked: () => unawaited(onTodayUnranked()),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                const SizedBox(height: 4),
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
                const SizedBox(height: 6),
                async.when(
                  loading: () => const _MonthCalendarShimmer(),
                  error: (e, _) => Text(
                    'Could not load Static War: $e',
                    style: AppTextStyles.bodySm().copyWith(
                      color: AppColors.wrong,
                    ),
                  ),
                  data: (bundle) {
                    final warsByDate = {
                      for (final w in bundle.wars) w.dateId: w,
                    };
                    if (snap.doc != null) {
                      warsByDate.putIfAbsent(
                        snap.doc!.dateId,
                        () => snap.doc!,
                      );
                    }
                    final submittedDates = bundle.submissions.keys.toSet();
                    if (snap.submission != null && snap.dateId.isNotEmpty) {
                      submittedDates.add(snap.dateId);
                    }
                    return DailyWarMonthCalendar(
                      year: displayedMonth.value.year,
                      month: displayedMonth.value.month,
                      warsByDate: warsByDate,
                      submittedDates: submittedDates,
                      minDate: minDate,
                      todayIso: todayIso,
                      liveDateId: live ? snap.dateId : null,
                      nowIst: ist,
                      onDateTap: (iso) => unawaited(onDateTap(iso)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: cardShadow,
          ),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: DailyWarEarnedBadgesSection(),
          ),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceTertiaryDark
          : AppColors.surfaceTertiaryLight,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(DailyWarCopy.programName),
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
      body: body,
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

class _MonthCalendarShimmer extends StatelessWidget {
  const _MonthCalendarShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: ShimmerBox(width: double.infinity, height: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 35,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, _) => const Padding(
            padding: EdgeInsets.all(4),
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppRadius.sm,
            ),
          ),
        ),
      ],
    );
  }
}
