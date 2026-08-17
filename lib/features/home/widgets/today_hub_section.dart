import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/domain/open_daily_ca_test.dart';
import '../../daily_ca/widgets/daily_ca_home_card.dart';
import '../../daily_war/domain/daily_war_copy.dart';
import '../../daily_war/domain/daily_war_models.dart';
import '../../daily_war/domain/daily_war_phase.dart';
import '../../daily_war/domain/daily_war_phase_resolver.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../../daily_war/providers/server_clock_provider.dart';
import '../../daily_war/theme/daily_war_theme.dart';
import '../../daily_war/widgets/daily_war_explainer_sheet.dart';
import '../../daily_war/widgets/daily_war_home_card.dart';
import '../domain/daily_streak_service.dart';
import '../domain/start_sunday_week_review.dart';
import '../domain/today_hero.dart';
import '../providers/sunday_week_review_provider.dart';
import '../providers/today_hub_provider.dart';
import 'daily_drill_card.dart';
import 'daily_revision_choice_sheet.dart';
import 'sunday_week_review_card.dart';
import 'today_loop_card.dart';

/// Daily ritual on home: one full-width hero, companions in a row.
///
/// Missing loops (Remote Config off, Sunday rest, not yet activated) simply
/// drop out — one companion becomes a banner, a single loop is just the hero.
class TodayHubSection extends HookConsumerWidget {
  const TodayHubSection({super.key, this.forceWarCollapsed = false});

  final bool forceWarCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(todayHubProvider);
    final scheme = Theme.of(context).colorScheme;

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

    final hubWarDoc = data.hubWarDoc(ist);
    final hubWarSubmitted = data.hubWarSubmitted(ist);
    final hubWarDateId = data.hubWarDateId(ist);
    final warTopics = data.hubWarTopics(ist);
    final overnight = TodayHero.usesYesterdayWar(ist);
    final sundayHub = TodayHero.isSundayHub(ist);

    final warPhase = DailyWarPhaseResolver.resolve(
      referenceIst: ist,
      firestoreStatus: hubWarDoc?.status,
      ranksReady: hubWarDoc?.ranksReady ?? false,
      questionCount: hubWarDoc?.questionCount ??
          DailyWarSchedule.questionCountForDate(TodayHero.hubDate(ist)),
    );
    final weekReview = sundayHub
        ? ref.watch(sundayWeekReviewProvider).asData?.value
        : null;

    final warAvailable =
        data.warEnabled && warPhase != DailyWarPhase.restDay && !sundayHub;
    final practiceAvailable = sundayHub
        ? weekReview != null
        : data.staticAvailable;
    final practiceDone = sundayHub
        ? (weekReview?.completedToday ?? false)
        : data.staticCompleted;

    final slots = TodayHero.slotsFrom(
      currentAvailable: data.caEnabled,
      currentDone: data.paperCompleted,
      practiceAvailable: practiceAvailable,
      practiceDone: practiceDone,
      warAvailable: warAvailable,
      warDone: hubWarSubmitted,
    );
    final pick = TodayHero.pick(
      istNow: ist,
      warUrgency: TodayHero.warUrgencyFor(warPhase),
      slots: slots,
      isSunday: sundayHub,
    );
    final hero = pick.hero;
    final fullDay = TodayHero.isFullDay(slots);
    final hour = ist.hour;
    final warEvening = hour >= TodayHero.warHourIst &&
        hour < TodayHero.warWindowEndHourIst;

    useEffect(() {
      if (!fullDay) return null;
      unawaited(() async {
        final prefs = await ref.read(prefsServiceProvider.future);
        DailyStreakService.recordFullDay(
          prefs: prefs,
          now: TodayHero.hubDate(ist),
        );
      }());
      return null;
    }, [fullDay, TodayHero.hubDate(ist).toIso8601String()]);

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

    Widget? cardFor(TodaySlotId id, TodayLoopLayout layout) {
      final isHero = id == hero && layout == TodayLoopLayout.hero;
      switch (id) {
        case TodaySlotId.current:
          if (!data.caEnabled) return null;
          return DailyCaHomeCard(
            paperDate: data.paperDate,
            isTodaysPaper: data.paperDate != null &&
                DailyCaSchedule.isTodaysPaper(
                  data.paperDate!,
                  referenceIst: ist,
                ),
            completed: data.paperCompleted,
            questionCount: DailyDrillConstants.questionCount,
            loading: launchingPaper.value,
            emphasized: isHero && !pick.caughtUp,
            layout: layout,
            onStart: openPaper,
          );
        case TodaySlotId.practice:
          if (sundayHub) {
            if (weekReview == null) return null;
            return SundayWeekReviewCard(
              mistakeCount: weekReview.uuids.length,
              completed: weekReview.completedToday,
              emphasized: isHero && !pick.caughtUp,
              loading: launchingReview.value,
              layout: layout,
              onStart: openWeekReview,
              onStartDrillInstead: data.staticAvailable
                  ? () {
                      unawaited(
                        showDailyRevisionChoiceSheet(
                          context: context,
                          ref: ref,
                          source: 'sunday_week_review_empty',
                          allowMixedFallback: true,
                        ),
                      );
                    }
                  : null,
            );
          }
          if (!data.staticAvailable) return null;
          return DailyDrillCard(
            emphasized: isHero && !pick.caughtUp,
            layout: layout,
          );
        case TodaySlotId.war:
          if (!data.warEnabled || sundayHub) return null;
          final useFullWar =
              isHero && !overnight && !pick.caughtUp && !forceWarCollapsed;
          if (useFullWar) {
            return DailyWarHomeCard(forceCollapsed: false);
          }
          return _HubWarCard(
            dateId: hubWarDateId,
            submitted: hubWarSubmitted,
            topics: warTopics,
            phase: warPhase,
            overnight: overnight,
            layout: layout,
            showNow: isHero && !pick.caughtUp,
            isGrand: hubWarDoc?.isGrand == true,
          );
      }
    }

    final companionIds = [
      for (final id in TodayHero.companions(hero, warEvening: warEvening))
        if (cardFor(id, TodayLoopLayout.tile) != null) id,
    ];
    final companionLayout = companionIds.length == 1
        ? TodayLoopLayout.banner
        : TodayLoopLayout.tile;
    final heroCard = cardFor(hero, TodayLoopLayout.hero);
    final companionCards = [
      for (final id in companionIds) cardFor(id, companionLayout),
    ].whereType<Widget>().toList();

    if (heroCard == null && companionCards.isEmpty) {
      return const SizedBox.shrink();
    }

    final kicker = pick.caughtUp
        ? 'DAY SEALED'
        : hour < TodayHero.paperHourIst ||
              hour >= TodayHero.warWindowEndHourIst
        ? 'STILL OPEN'
        : hour < TodayHero.practiceHourIst
        ? 'THIS MORNING'
        : hour < TodayHero.warHourIst
        ? 'THIS AFTERNOON'
        : 'TONIGHT';
    final subline = pick.caughtUp
        ? 'Nothing left on the table today.'
        : kicker == 'STILL OPEN'
        ? 'Today isn\'t closed yet.'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kicker,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        if (subline != null) ...[
          const SizedBox(height: 2),
          Text(
            subline,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ?heroCard,
        if (companionCards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          if (companionCards.length == 1)
            companionCards.first
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < companionCards.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: companionCards[i]),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _HubWarCard extends StatelessWidget {
  const _HubWarCard({
    required this.dateId,
    required this.submitted,
    required this.topics,
    required this.phase,
    required this.overnight,
    required this.layout,
    required this.showNow,
    required this.isGrand,
  });

  final String dateId;
  final bool submitted;
  final List<DailyWarTopicRef> topics;
  final DailyWarPhase phase;
  final bool overnight;
  final TodayLoopLayout layout;
  final bool showNow;
  final bool isGrand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = phase == DailyWarPhase.lobby ||
        phase == DailyWarPhase.liveJoinable ||
        phase == DailyWarPhase.liveLocked;
    final topicsLine = DailyWarCopy.topicsLine(topics);

    final String title;
    final String subtitle;
    final String cta;
    if (submitted) {
      title = layout == TodayLoopLayout.tile
          ? 'Daily War'
          : (topicsLine.isEmpty ? 'Daily War' : topicsLine);
      subtitle = layout == TodayLoopLayout.tile
          ? 'You were there'
          : 'You were in the room. The rank is waiting.';
      cta = layout == TodayLoopLayout.hero ? 'See how you did' : 'Result';
    } else if (live) {
      title = 'Daily War';
      subtitle = 'The room is open.';
      cta = 'Join';
    } else if (overnight ||
        phase == DailyWarPhase.resultsPending ||
        phase == DailyWarPhase.resultsReady) {
      title = topicsLine.isEmpty ? 'Last night' : topicsLine;
      subtitle = layout == TodayLoopLayout.tile
          ? 'Missed'
          : 'The paper is up if you still want the questions.';
      cta = layout == TodayLoopLayout.hero ? 'Open the paper' : 'Paper';
    } else {
      title = layout == TodayLoopLayout.tile
          ? 'Daily War'
          : (topicsLine.isEmpty ? 'Two topics a night' : topicsLine);
      subtitle = layout == TodayLoopLayout.tile
          ? '9 PM'
          : 'Same paper. Whole country. Warm up first.';
      cta = 'How it works';
    }

    return TodayLoopCard(
      layout: layout,
      eyebrow: live ? 'LIVE' : '9 PM',
      title: title,
      subtitle: subtitle,
      cta: cta,
      icon: Icons.shield_outlined,
      accent: DwColors.crimsonBright,
      background: isDark ? DwColors.surface : DwColors.crimsonSoft,
      foreground: isDark ? DwColors.onDark : null,
      mutedForeground: isDark ? DwColors.onDarkMuted : null,
      onTap: () {
        if (live) {
          context.push('/daily-war');
          return;
        }
        if (submitted ||
            overnight ||
            phase == DailyWarPhase.resultsPending ||
            phase == DailyWarPhase.resultsReady) {
          if (dateId.isEmpty) return;
          context.push('/daily-war/history/$dateId');
          return;
        }
        unawaited(
          showDailyWarExplainerSheet(
            context: context,
            topics: topics,
            isGrand: isGrand,
          ),
        );
      },
      done: submitted,
      showNow: showNow,
    );
  }
}
