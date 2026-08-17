import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/domain/open_daily_ca_test.dart';
import '../../daily_ca/widgets/daily_ca_home_card.dart';
import '../../daily_war/domain/daily_war_phase.dart';
import '../../daily_war/domain/daily_war_phase_resolver.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../../daily_war/providers/server_clock_provider.dart';
import '../../daily_war/widgets/daily_war_home_card.dart';
import '../domain/daily_streak_service.dart';
import '../domain/start_daily_drill.dart';
import '../domain/start_sunday_week_review.dart';
import '../domain/today_hero.dart';
import '../providers/sunday_week_review_provider.dart';
import '../providers/today_hub_provider.dart';
import 'daily_drill_card.dart';
import 'sunday_week_review_card.dart';

/// Three daily widgets on home. One is highlighted by time of day.
///
/// Weekdays: 6 AM–noon paper, noon–6 PM drill, 6–9 PM War.
/// Sunday: 6 AM–noon Saturday's paper, noon onward last week's mistakes.
class TodayHubSection extends HookConsumerWidget {
  const TodayHubSection({super.key, this.forceWarCollapsed = false});

  /// True while the activation checklist should stay the loudest thing on home.
  final bool forceWarCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(todayHubProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
    final tick = useState(0);
    useEffect(() {
      final t = Timer.periodic(
        const Duration(seconds: 1),
        (_) => tick.value++,
      );
      return t.cancel;
    }, const []);
    tick.value;

    final ist = DailyWarSchedule.nowIst(
      DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch + offset,
        isUtc: true,
      ),
    );

    final warPhase = DailyWarPhaseResolver.resolve(
      referenceIst: ist,
      firestoreStatus: data.warDoc?.status,
      ranksReady: data.warDoc?.ranksReady ?? false,
      questionCount: data.warDoc?.questionCount ??
          DailyWarSchedule.questionCountForDate(
            DailyWarSchedule.warDateFor(ist),
          ),
    );
    final isSunday = DailyWarSchedule.isSunday(ist);
    final weekReview = isSunday
        ? ref.watch(sundayWeekReviewProvider).asData?.value
        : null;

    final warAvailable =
        data.warEnabled && warPhase != DailyWarPhase.restDay;
    final practiceAvailable = isSunday
        ? weekReview != null
        : data.staticAvailable;
    final practiceDone = isSunday
        ? (weekReview?.completedToday ?? false)
        : data.staticCompleted;

    final slots = TodayHero.slotsFrom(
      currentAvailable: data.caEnabled,
      currentDone: data.paperCompleted,
      practiceAvailable: practiceAvailable,
      practiceDone: practiceDone,
      warAvailable: warAvailable,
      warDone: data.warSubmitted,
    );
    final hero = TodayHero.heroFor(
      istNow: ist,
      warUrgency: TodayHero.warUrgencyFor(warPhase),
      slots: slots,
      isSunday: isSunday,
    );
    final fullDay = TodayHero.isFullDay(slots);

    useEffect(() {
      if (!fullDay) return null;
      unawaited(() async {
        final prefs = await ref.read(prefsServiceProvider.future);
        DailyStreakService.recordFullDay(prefs: prefs);
      }());
      return null;
    }, [fullDay]);

    final launchingPaper = useState(false);
    final launchingReview = useState(false);

    Future<void> openPaper() async {
      final iso = data.paperDateIso;
      if (iso == null || launchingPaper.value) return;
      launchingPaper.value = true;
      try {
        await openDailyCaTest(
          context: context,
          ref: ref,
          isoDate: iso,
          isRevise: data.paperCompleted,
          onFinished: () => ref.invalidate(todayHubProvider),
        );
      } finally {
        launchingPaper.value = false;
      }
    }

    Future<void> openWeekReview() async {
      final uuids = weekReview?.uuids ?? const <String>[];
      if (uuids.isEmpty || launchingReview.value) return;
      launchingReview.value = true;
      try {
        await startSundayWeekReview(context: context, ref: ref, uuids: uuids);
      } finally {
        launchingReview.value = false;
      }
    }

    if (!data.caEnabled &&
        !data.staticAvailable &&
        !data.warEnabled &&
        weekReview == null) {
      return const SizedBox.shrink();
    }

    Widget? cardFor(TodaySlotId id) {
      final isHero = id == hero;
      switch (id) {
        case TodaySlotId.current:
          if (!data.caEnabled) return null;
          return DailyCaHomeCard(
            borderColor: borderColor,
            paperDate: data.paperDate,
            isTodaysPaper: data.paperDate != null &&
                DailyCaSchedule.isTodaysPaper(
                  data.paperDate!,
                  referenceIst: ist,
                ),
            completed: data.paperCompleted,
            questionCount: DailyDrillConstants.questionCount,
            loading: launchingPaper.value,
            emphasized: isHero,
            onStart: openPaper,
          );
        case TodaySlotId.practice:
          if (isSunday) {
            if (weekReview == null) return null;
            return SundayWeekReviewCard(
              mistakeCount: weekReview.uuids.length,
              completed: weekReview.completedToday,
              emphasized: isHero,
              loading: launchingReview.value,
              onStart: openWeekReview,
              onStartDrillInstead: data.staticAvailable
                  ? () {
                      unawaited(
                        startDailyDrill(
                          context: context,
                          ref: ref,
                          subject: data.staticSubject,
                          source: 'sunday_week_review_empty',
                          completedToday: data.staticCompleted,
                        ),
                      );
                    }
                  : null,
            );
          }
          if (!data.staticAvailable) return null;
          return DailyDrillCard(emphasized: isHero);
        case TodaySlotId.war:
          if (!data.warEnabled) return null;
          return DailyWarHomeCard(
            forceCollapsed: forceWarCollapsed || !isHero,
          );
      }
    }

    final cards = <Widget>[];
    for (final id in TodayHero.displayOrder(hero)) {
      final card = cardFor(id);
      if (card == null) continue;
      if (cards.isNotEmpty) {
        cards.add(const SizedBox(height: AppSpacing.md));
      }
      cards.add(id == hero ? _NowWrap(child: card) : card);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TODAY',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...cards,
      ],
    );
  }
}

class _NowWrap extends StatelessWidget {
  const _NowWrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'NOW',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}
