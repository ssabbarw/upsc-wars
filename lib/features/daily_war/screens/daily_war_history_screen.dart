import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_prompt_policy.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../daily_war_constants.dart';
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

    final live =
        snap.phase == DailyWarPhase.lobby ||
        snap.phase == DailyWarPhase.liveJoinable;

    Future<void> joinLive() async {
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

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
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
              onPressed: canGoToNextMonth ? () => shiftMonth(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const _MonthCalendarShimmer(),
          error: (e, _) => Text(
            'Could not load Wars: $e',
            style: AppTextStyles.bodySm().copyWith(color: AppColors.wrong),
          ),
          data: (bundle) {
            final warsByDate = {for (final w in bundle.wars) w.dateId: w};
            if (snap.doc != null) {
              warsByDate.putIfAbsent(snap.doc!.dateId, () => snap.doc!);
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
        const SizedBox(height: AppSpacing.lg),
        const DailyWarEarnedBadgesSection(),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Daily War',
          style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
        ),
      ),
      body: body,
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
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
          ),
          itemBuilder: (_, _) => const Padding(
            padding: EdgeInsets.all(6),
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppRadius.pill,
            ),
          ),
        ),
      ],
    );
  }
}
