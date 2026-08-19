import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
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
import '../../daily_war/domain/daily_war_copy.dart';
import '../../daily_war/domain/daily_war_models.dart';
import '../../daily_war/domain/daily_war_phase.dart';
import '../../daily_war/domain/daily_war_phase_resolver.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../../daily_war/providers/server_clock_provider.dart';
import '../../daily_war/theme/daily_war_theme.dart';
import '../../daily_war/widgets/daily_war_explainer_sheet.dart';
import '../../daily_war/widgets/daily_war_home_card.dart';
import '../../daily_war/widgets/daily_war_topics_sheet.dart';
import '../../fomo_pulse/widgets/fomo_pulse_home_card.dart';
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
      final t = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
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
      questionCount:
          hubWarDoc?.questionCount ??
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
    final warEvening =
        hour >= TodayHero.warHourIst && hour < TodayHero.warWindowEndHourIst;

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
            isTodaysPaper:
                data.paperDate != null &&
                DailyCaSchedule.isTodaysPaper(
                  data.paperDate!,
                  referenceIst: ist,
                ),
            completed: data.paperCompleted,
            questionCount: DailyDrillConstants.questionCount,
            loading: launchingPaper.value || data.paperChecking,
            questionsReady: data.paperLive,
            emphasized: isHero && !pick.caughtUp,
            layout: layout,
            onStart: data.paperLive ? openPaper : null,
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

    Widget rowOf(List<Widget> cards) {
      if (cards.length == 1) return cards.first;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      );
    }

    Widget withShots(Widget ca) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      return _CaGroup(borderColor: borderColor, ca: ca);
    }

    // Returns an "Available from …" label when the slot has no content yet.
    // War always has topics/info to show, so it is never dimmed.
    // Practice is only dimmed before noon when the drill hasn't been assigned.
    String? upcomingLabelFor(TodaySlotId id) {
      if (pick.caughtUp) return null;
      switch (id) {
        case TodaySlotId.current:
          return null;
        case TodaySlotId.practice:
          if (!sundayHub && !data.staticAvailable &&
              hour < TodayHero.practiceHourIst) return 'From 12 PM';
          return null;
        case TodaySlotId.war:
          // War card always shows topics or "Tonight at 9 PM" — never dim it.
          return null;
      }
    }

    Widget? placed(TodaySlotId id, TodayLoopLayout layout) {
      final card = cardFor(id, layout);
      if (card == null) return null;
      final base = id == TodaySlotId.current ? withShots(card) : card;
      final label = id != hero ? upcomingLabelFor(id) : null;
      if (label == null) return base;
      return _UpcomingCompanionWrap(label: label, child: base);
    }

    final companionIds = [
      for (final id in TodayHero.companions(hero, warEvening: warEvening))
        if (cardFor(id, TodayLoopLayout.tile) != null) id,
    ];
    // War topics and the CA+shots pair need full width — keep them out of
    // the half-width tile row.
    final companionBlocks = <Widget>[];
    var rowIds = <TodaySlotId>[];

    void flushRow() {
      if (rowIds.isEmpty) return;
      final layout = rowIds.length == 1
          ? TodayLoopLayout.banner
          : TodayLoopLayout.tile;
      final cards = [
        for (final id in rowIds) cardFor(id, layout),
      ].whereType<Widget>().toList();
      if (cards.isNotEmpty) companionBlocks.add(rowOf(cards));
      rowIds = [];
    }

    for (final id in companionIds) {
      if (id == TodaySlotId.war || id == TodaySlotId.current) {
        flushRow();
        final block = placed(id, TodayLoopLayout.banner);
        if (block != null) companionBlocks.add(block);
      } else {
        rowIds.add(id);
      }
    }
    flushRow();

    final heroCard = placed(hero, TodayLoopLayout.hero);

    if (heroCard == null && companionBlocks.isEmpty) {
      return const SizedBox.shrink();
    }

    final kicker = pick.caughtUp
        ? 'DAY SEALED'
        : hour < TodayHero.paperHourIst || hour >= TodayHero.warWindowEndHourIst
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
        for (final block in companionBlocks) ...[
          const SizedBox(height: AppSpacing.md),
          block,
        ],
        if (!data.caEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          const FomoPulseHomeCard(),
        ],
      ],
    );
  }
}

/// Groups the Daily CA card and CA Shots in one outlined container so they
/// read as a single "Current Affairs" block.
class _CaGroup extends StatelessWidget {
  const _CaGroup({required this.borderColor, required this.ca});

  final Color borderColor;
  final Widget ca;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CA daily-test card — strip its own outline so the group owns it
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            ),
            child: ca,
          ),
          Divider(height: AppSpacing.sm * 2, thickness: 0.5, color: borderColor),
          // CA Shots row
          InkWell(
            onTap: () => context.push('/fomo-pulse'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: scheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current affairs shots',
                          style: AppTextStyles.label().copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Breaking CA brief, then 1 MCQ shot',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                    size: 20,
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
    final live =
        phase == DailyWarPhase.lobby ||
        phase == DailyWarPhase.liveJoinable ||
        phase == DailyWarPhase.liveLocked;
    final resultsOpen =
        overnight ||
        phase == DailyWarPhase.resultsPending ||
        phase == DailyWarPhase.resultsReady;
    // Saturday Grand War revisits the whole week (~10 topics). Don't stack
    // them — weekdays keep the two-topic title.
    final weekend = isGrand || topics.length > 2;
    final warName = isGrand ? 'Grand War' : 'Daily War';
    final warEyebrow = isGrand ? 'GRAND WAR' : 'DAILY WAR';
    final weekBit = topics.isEmpty
        ? 'Week revision'
        : 'Week revision · ${topics.length} topics';

    final String title;
    final String subtitle;
    final String cta;
    final String eyebrow;
    final int titleMaxLines;
    if (weekend) {
      titleMaxLines = 1;
      if (submitted) {
        title = warName;
        subtitle = layout == TodayLoopLayout.tile ? 'You were there' : weekBit;
        cta = layout == TodayLoopLayout.hero ? 'See how you did' : 'Result';
        eyebrow = warEyebrow;
      } else if (live) {
        title = warName;
        subtitle = layout == TodayLoopLayout.tile
            ? 'Join now'
            : '$weekBit. The room is open.';
        cta = 'Join';
        eyebrow = 'LIVE';
      } else if (resultsOpen) {
        title = warName;
        subtitle = layout == TodayLoopLayout.tile
            ? 'Last night'
            : 'Last night · $weekBit';
        cta = layout == TodayLoopLayout.hero ? 'Open the paper' : 'Paper';
        eyebrow = 'LAST NIGHT';
      } else {
        title = 'Saturday at 9 PM';
        subtitle = layout == TodayLoopLayout.tile
            ? weekBit
            : '$weekBit. Same paper, All-India.';
        cta = topics.isNotEmpty ? 'See topics' : 'How it works';
        eyebrow = warEyebrow;
      }
    } else {
      final topicsLine = DailyWarCopy.topicsLine(topics, sep: '\n');
      final topicTitle = topicsLine.isEmpty ? null : topicsLine;
      titleMaxLines = topics.isEmpty ? 2 : (topics.length * 2).clamp(2, 4);
      if (submitted) {
        title = topicTitle ?? warName;
        subtitle = layout == TodayLoopLayout.tile
            ? 'You were there'
            : 'You were in the room. The rank is waiting.';
        cta = layout == TodayLoopLayout.hero ? 'See how you did' : 'Result';
        eyebrow = warEyebrow;
      } else if (live) {
        title = topicTitle ?? warName;
        subtitle = layout == TodayLoopLayout.tile
            ? 'Join the live paper'
            : 'Live All-India paper. Same questions, then the rank.';
        cta = 'Join';
        eyebrow = 'LIVE';
      } else if (resultsOpen) {
        title = topicTitle ?? warName;
        subtitle = layout == TodayLoopLayout.tile
            ? 'Last night\'s paper'
            : 'Last night\'s paper is up if you still want the questions.';
        cta = layout == TodayLoopLayout.hero ? 'Open the paper' : 'Paper';
        eyebrow = 'LAST NIGHT';
      } else {
        title = topicTitle ?? 'Tonight at 9 PM';
        subtitle = layout == TodayLoopLayout.tile
            ? 'All-India live test · 9 PM'
            : 'All-India live test. Tonight at 9 PM.';
        cta = 'How it works';
        eyebrow = warEyebrow;
      }
    }

    return TodayLoopCard(
      layout: layout,
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      cta: cta,
      titleMaxLines: titleMaxLines,
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
        if (submitted || resultsOpen) {
          if (dateId.isEmpty) return;
          context.push('/daily-war/history/$dateId');
          return;
        }
        if (weekend && topics.isNotEmpty) {
          unawaited(showDailyWarTopicsSheet(context: context, topics: topics));
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

/// Wraps a companion card with reduced opacity and an "Available from …" label
/// to signal that the card's time window has not started yet.
class _UpcomingCompanionWrap extends StatelessWidget {
  const _UpcomingCompanionWrap({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IgnorePointer(child: child),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
