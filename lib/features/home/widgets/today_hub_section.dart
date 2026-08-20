import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/domain/open_daily_ca_test.dart';
import '../../daily_ca/widgets/daily_ca_unavailable_sheet.dart';
import '../../daily_war/daily_war_constants.dart';
import '../../daily_war/domain/daily_war_copy.dart';
import '../../daily_war/domain/daily_war_models.dart';
import '../../daily_war/domain/daily_war_phase.dart';
import '../../daily_war/domain/daily_war_phase_resolver.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../../daily_war/providers/server_clock_provider.dart';
import '../../daily_war/theme/daily_war_theme.dart';
import '../../daily_war/widgets/daily_war_home_card.dart';
import '../domain/activation_journey_constants.dart';
import '../domain/daily_revision.dart';
import '../domain/daily_streak_service.dart';
import '../domain/start_sunday_week_review.dart';
import '../domain/today_hero.dart';
import '../providers/sunday_week_review_provider.dart';
import '../providers/today_hub_provider.dart';
import '../providers/home_activation_journey_provider.dart';
import 'activation_journey_card.dart';
import 'daily_revision_choice_sheet.dart';

/// Daily ritual on home: one full-width hero card + a flat "Keep going" list.
///
/// The hero card changes based on time of day and which activity is most urgent.
/// Keep going always lists CA Shots, Current Affairs test, Daily War,
/// Danger Zone, and Revision queue — independent of the hero.
class TodayHubSection extends HookConsumerWidget {
  const TodayHubSection({
    super.key,
    this.activationJourney,
    this.activationJourneyLoading = false,
  });

  final HomeActivationJourneyState? activationJourney;

  /// True on the first load, before we know whether START HERE should win.
  /// Avoids flashing the time-of-day hero for a new user.
  final bool activationJourneyLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(todayHubProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final warAvailable = sundayHub
        ? weekReview != null
        : data.warEnabled && warPhase != DailyWarPhase.restDay;
    final queueEmpty =
        data.revisionWrongCount <= 0 && data.revisionBookmarkCount <= 0;
    final practiceAvailable = data.staticAvailable && !queueEmpty;
    final practiceDone = data.staticCompleted;
    final warDone = sundayHub
        ? (weekReview?.completedToday ?? false)
        : hubWarSubmitted;

    final slots = TodayHero.slotsFrom(
      currentAvailable: data.caEnabled,
      currentDone: data.paperCompleted,
      practiceAvailable: practiceAvailable,
      practiceDone: practiceDone,
      warAvailable: warAvailable,
      warDone: warDone,
    );
    final pick = TodayHero.pick(
      istNow: ist,
      warUrgency: TodayHero.warUrgencyFor(warPhase),
      slots: slots,
      isSunday: sundayHub,
      paperRevised: data.paperResultsOpened,
      revisionQueueEmpty: queueEmpty,
    );
    final hero = pick.hero;
    final fullDay = TodayHero.isFullDay(slots);

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
    // TEMP: cycle home hero items/states without waiting on the clock.
    final heroPreview = useState(_HeroPreviewId.live);

    Future<void> openPaper() async {
      final iso = data.paperDateIso;
      if (iso == null || launchingPaper.value) return;
      launchingPaper.value = true;
      try {
        await openDailyCaTest(
          context: context,
          ref: ref,
          isoDate: iso,
          isRevise: false,
          onFinished: () => ref.invalidate(todayHubProvider),
        );
      } finally {
        launchingPaper.value = false;
      }
    }

    Future<void> openPaperResults() async {
      final iso = data.paperDateIso;
      if (iso == null || launchingPaper.value) return;
      launchingPaper.value = true;
      try {
        final db = ref.read(userDatabaseProvider);
        final sessionId = await db.sessionsDao
            .getLatestCompletedDailyCaSessionId(iso);
        if (!context.mounted) return;
        if (sessionId == null) {
          await openDailyCaTest(
            context: context,
            ref: ref,
            isoDate: iso,
            isRevise: true,
            onFinished: () => ref.invalidate(todayHubProvider),
          );
          return;
        }
        context.push('/results/$sessionId');
      } finally {
        launchingPaper.value = false;
      }
    }

    void openPaperOrUnavailable() {
      if (data.paperCompleted) {
        unawaited(openPaperResults());
        return;
      }
      if (data.paperLive) {
        unawaited(openPaper());
        return;
      }
      unawaited(
        showDailyCaUnavailableSheet(
          context: context,
          availableFrom: DailyCaSchedule.nextOpensAt(referenceIst: ist),
          pendingLive: data.paperDate != null,
          onSeeHistory: () {
            if (context.mounted) context.push('/daily-ca');
          },
        ),
      );
    }

    void openWarSurface() {
      context.push(dailyWarHistoryRoute());
    }

    void openLastNightWar() {
      context.push(dailyWarHistoryDetailRoute(data.yesterdayWarDateId));
    }

    Future<void> openWarResults() async {
      final dateId = data.hubWarDateId(ist);
      final db = ref.read(userDatabaseProvider);
      final sessionId = await db.sessionsDao
          .getLatestCompletedDailyWarSessionId(dateId);
      if (!context.mounted) return;
      if (sessionId != null) {
        context.push(dailyWarResultsRoute(sessionId));
        return;
      }
      context.push(dailyWarHistoryDetailRoute(dateId));
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

    Future<void> openWeekReviewResults() async {
      if (launchingReview.value) return;
      launchingReview.value = true;
      String? sessionId;
      try {
        final db = ref.read(userDatabaseProvider);
        sessionId = await db.sessionsDao
            .getLatestCompletedSundayWeekReviewSessionId(
              startInclusive: TodayHero.hubWindowStart(ist),
              endExclusive: TodayHero.hubWindowEnd(ist),
            );
        if (!context.mounted) return;
        if (sessionId != null) {
          context.push('/results/$sessionId');
        }
      } finally {
        launchingReview.value = false;
      }
      if (sessionId == null) await openWeekReview();
    }

    void openQuickPractice() {
      unawaited(
        showDailyRevisionChoiceSheet(
          context: context,
          ref: ref,
          source: 'today_hub_week_review_empty',
        ),
      );
    }

    VoidCallback? weekReviewTap({
      required bool completed,
      required int mistakeCount,
    }) {
      if (completed) return () => unawaited(openWeekReviewResults());
      if (mistakeCount <= 0) return openQuickPractice;
      return () => unawaited(openWeekReview());
    }

    // ── War phase helpers ────────────────────────────────────────────────────
    final warLive = warPhase == DailyWarPhase.liveJoinable;
    final warResultsOpen =
        overnight ||
        warPhase == DailyWarPhase.resultsPending ||
        warPhase == DailyWarPhase.resultsReady;
    final isGrand = hubWarDoc?.isGrand == true;
    final weekend = isGrand || warTopics.length > 2;
    final warName = DailyWarCopy.eventName(isGrand: isGrand);

    // ── Hero card content ────────────────────────────────────────────────────

    // Returns the hero card widget for the given hero slot.
    Widget buildHeroCard() {
      switch (hero) {
        case TodaySlotId.war:
          if (sundayHub) {
            if (weekReview == null) break;
            return _PracticeHeroCard(
              isSunday: true,
              mistakeCount: weekReview.uuids.length,
              completed: weekReview.completedToday,
              loading: launchingReview.value,
              onStart: weekReviewTap(
                completed: weekReview.completedToday,
                mistakeCount: weekReview.uuids.length,
              ),
            );
          }
          if (!data.warEnabled) break;
          // Same clock card as evening War — including empty-queue fallthrough.
          // Compact card is only overnight last-night / caught-up.
          final useFullWar = !overnight && !pick.caughtUp;
          if (useFullWar) {
            return const DailyWarHomeCard();
          }
          return _WarHeroCard(
            submitted: hubWarSubmitted,
            topics: warTopics,
            phase: warPhase,
            overnight: overnight,
            isGrand: isGrand,
            caughtUp: pick.caughtUp,
            onTap: hubWarSubmitted
                ? () => unawaited(openWarResults())
                : overnight
                ? openLastNightWar
                : openWarSurface,
          );

        case TodaySlotId.current:
          if (!data.caEnabled) break;
          return _CaHeroCard(
            paperDate: data.paperDate,
            isTodaysPaper:
                data.paperDate != null &&
                DailyCaSchedule.isTodaysPaper(
                  data.paperDate!,
                  referenceIst: ist,
                ),
            completed: data.paperCompleted,
            loading: launchingPaper.value || data.paperChecking,
            questionsReady: data.paperLive,
            onStart: openPaperOrUnavailable,
          );

        case TodaySlotId.practice:
          if (!data.staticAvailable) break;
          return _PracticeHeroCard(
            isSunday: false,
            mistakeCount: 0,
            wrongCount: data.revisionWrongCount,
            bookmarkCount: data.revisionBookmarkCount,
            completed: data.staticCompleted,
            loading: false,
            onStart: () {
              unawaited(
                showDailyRevisionChoiceSheet(
                  context: context,
                  ref: ref,
                  source: 'today_hub_hero',
                ),
              );
            },
          );
      }

      return const SizedBox.shrink();
    }

    Widget buildForcedHero(_HeroPreviewId preview) {
      final dummyPaper = DateTime(2026, 8, 18);
      const dummyTopics = [
        DailyWarTopicRef(subjectSlug: 'polity', topic: 'Fundamental Rights'),
        DailyWarTopicRef(subjectSlug: 'economy', topic: 'Monetary Policy'),
      ];

      switch (preview) {
        case _HeroPreviewId.live:
          return buildHeroCard();
        case _HeroPreviewId.caSoon:
          return _CaHeroCard(
            paperDate: null,
            isTodaysPaper: false,
            completed: false,
            loading: false,
            questionsReady: false,
            onStart: openPaperOrUnavailable,
          );
        case _HeroPreviewId.caPreparing:
          return _CaHeroCard(
            paperDate: dummyPaper,
            isTodaysPaper: true,
            completed: false,
            loading: false,
            questionsReady: false,
            onStart: openPaperOrUnavailable,
          );
        case _HeroPreviewId.caReady:
          return _CaHeroCard(
            paperDate: dummyPaper,
            isTodaysPaper: true,
            completed: false,
            loading: false,
            questionsReady: true,
            onStart: openPaperOrUnavailable,
          );
        case _HeroPreviewId.caDone:
          return _CaHeroCard(
            paperDate: dummyPaper,
            isTodaysPaper: true,
            completed: true,
            loading: false,
            questionsReady: true,
            onStart: openPaperOrUnavailable,
          );
        case _HeroPreviewId.practiceEmpty:
          return const DailyWarHomeCard();
        case _HeroPreviewId.practiceOpen:
          return _PracticeHeroCard(
            isSunday: false,
            mistakeCount: 0,
            wrongCount: 12,
            bookmarkCount: 5,
            completed: false,
            loading: false,
            onStart: () {
              unawaited(
                showDailyRevisionChoiceSheet(
                  context: context,
                  ref: ref,
                  source: 'today_hub_hero',
                ),
              );
            },
          );
        case _HeroPreviewId.practiceDone:
          return _PracticeHeroCard(
            isSunday: false,
            mistakeCount: 0,
            wrongCount: 12,
            bookmarkCount: 5,
            completed: true,
            loading: false,
            onStart: () {
              unawaited(
                showDailyRevisionChoiceSheet(
                  context: context,
                  ref: ref,
                  source: 'today_hub_hero',
                ),
              );
            },
          );
        case _HeroPreviewId.warClock:
          return const DailyWarHomeCard();
        case _HeroPreviewId.warLastNight:
          return _WarHeroCard(
            submitted: false,
            topics: dummyTopics,
            phase: DailyWarPhase.resultsReady,
            overnight: true,
            isGrand: false,
            caughtUp: false,
            onTap: openLastNightWar,
          );
        case _HeroPreviewId.warCaughtUp:
          return _WarHeroCard(
            submitted: true,
            topics: dummyTopics,
            phase: DailyWarPhase.resultsReady,
            overnight: false,
            isGrand: false,
            caughtUp: true,
            onTap: () => unawaited(openWarResults()),
          );
      }
    }

    // ── Keep going list — always the same set, independent of the hero ─────

    List<_TodayListRowData> buildListRows() {
      final rows = <_TodayListRowData>[];

      if (data.caEnabled) {
        rows.add(_caShotsListRow(context));
        rows.add(
          _TodayListRowData(
            icon: Icons.article_outlined,
            accent: AppColors.info,
            title: 'Daily Current Affairs Test',
            subtitle: !data.paperCompleted
                ? "Current affairs test from yesterday's news."
                : data.paperResultsOpened
                ? 'Done today'
                : 'Quiz done — open answers',
            done: data.paperCompleted && data.paperResultsOpened,
            locked: false,
            onTap: () => context.push('/daily-ca'),
          ),
        );
      }

      if (data.warEnabled) {
        final warTitle = warLive
            ? '${DailyWarCopy.eventName(isGrand: isGrand)} — LIVE'
            : warResultsOpen
            ? '${DailyWarCopy.eventName(isGrand: isGrand)} — last night'
            : warName;
        rows.add(
          _TodayListRowData(
            icon: Icons.shield_outlined,
            accent: DwColors.crimsonBright,
            title: warTitle,
            subtitle: _warListSubtitle(
              submitted: hubWarSubmitted,
              live: warLive,
              resultsOpen: warResultsOpen,
              topics: warTopics,
              phase: warPhase,
              isGrand: isGrand,
              weekend: weekend,
            ),
            done: hubWarSubmitted,
            locked: false,
            onTap: openWarSurface,
          ),
        );
      }

      final scored = activationJourney?.scoredAttempts;
      final unlockAt = ActivationJourneyConstants.confidenceMapUnlockAttempts;
      final unlocked = scored != null && scored >= unlockAt;
      rows.add(
        _TodayListRowData(
          icon: Icons.lock_outline_rounded,
          accent: AppColors.wrong,
          title: 'Danger Zone',
          subtitle: unlocked
              ? 'Questions you got wrong while sure — trap patterns.'
              : scored == null
              ? 'Questions you got wrong while sure. Unlocks at $unlockAt questions.'
              : 'Questions you got wrong while sure. Unlocks at $unlockAt questions. — $scored/$unlockAt so far.',
          subtitleMaxLines: 2,
          done: false,
          locked: !unlocked,
          onTap: unlocked ? () => context.push('/weak-areas/traps') : null,
        ),
      );

      if (data.staticAvailable) {
        rows.add(
          _TodayListRowData(
            icon: Icons.replay_rounded,
            accent: AppColors.primary,
            title: 'Revision queue',
            subtitle: queueEmpty
                ? DailyRevision.emptyQueueLine
                : data.staticCompleted
                ? 'Done today'
                : DailyRevision.countsLine(
                    missed: data.revisionWrongCount,
                    saved: data.revisionBookmarkCount,
                  ),
            done: !queueEmpty && data.staticCompleted,
            locked: queueEmpty,
            onTap: queueEmpty
                ? null
                : () {
                    unawaited(
                      showDailyRevisionChoiceSheet(
                        context: context,
                        ref: ref,
                        source: 'today_hub_list',
                      ),
                    );
                  },
          ),
        );
      }

      if (sundayHub && weekReview != null) {
        rows.add(
          _TodayListRowData(
            icon: Icons.history_edu_rounded,
            accent: AppColors.warning,
            title: 'Week Review',
            subtitle: weekReview.completedToday
                ? 'Done today'
                : '${weekReview.uuids.length} mistakes to revisit',
            done: weekReview.completedToday,
            locked: false,
            onTap: weekReviewTap(
              completed: weekReview.completedToday,
              mistakeCount: weekReview.uuids.length,
            ),
            loading: launchingReview.value,
          ),
        );
      }

      return rows;
    }

    final listRows = buildListRows();

    if (!data.caEnabled && !data.warEnabled && !data.staticAvailable) {
      return const SizedBox.shrink();
    }

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // When activation checklist is active, show it as the hero instead.
    // A forced preview wins so we can inspect time-of-day cards on a new user.
    final journey = activationJourney;
    final forcedPreview =
        kDebugMode && heroPreview.value != _HeroPreviewId.live;
    final Widget heroWidget;
    if (forcedPreview) {
      heroWidget = buildForcedHero(heroPreview.value);
    } else if (activationJourneyLoading) {
      heroWidget = const _HeroLoadingCard();
    } else if (journey != null && journey.shouldShowChecklist) {
      heroWidget = ActivationJourneyCard(state: journey);
    } else {
      heroWidget = buildHeroCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kDebugMode) ...[
          _HeroPreviewBar(
            preview: heroPreview.value,
            onCycleItem: () {
              heroPreview.value = heroPreview.value.nextItem;
            },
            onCycleState: () {
              heroPreview.value = heroPreview.value.nextState;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // ── Hero card ──────────────────────────────────────────────────────
        heroWidget,

        // ── TODAY list ─────────────────────────────────────────────────────
        if (listRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keep going',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < listRows.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: borderColor,
                        indent: 16,
                        endIndent: 0,
                      ),
                    _TodayListRow(data: listRows[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── List row data ─────────────────────────────────────────────────────────────

class _TodayListRowData {
  const _TodayListRowData({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.locked,
    this.subtitleMaxLines = 1,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final int subtitleMaxLines;
  final bool done;
  final bool locked;
  final VoidCallback? onTap;
  final bool loading;
}

class _TodayListRow extends StatelessWidget {
  const _TodayListRow({required this.data});

  final _TodayListRowData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = data.locked
        ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
        : data.accent;
    final fg = data.locked ? scheme.onSurfaceVariant : scheme.onSurface;

    return Opacity(
      opacity: data.locked ? 0.7 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.locked ? null : data.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Icon well
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: data.locked
                        ? scheme.surfaceContainerLow
                        : accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    data.done
                        ? Icons.check_rounded
                        : data.locked
                        ? Icons.lock_outline_rounded
                        : data.icon,
                    color: data.done ? data.accent : accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label().copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        maxLines: data.subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (data.loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                else if (data.locked)
                  const SizedBox.shrink()
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── TODAY list helpers ────────────────────────────────────────────────────────

_TodayListRowData _caShotsListRow(BuildContext context) {
  return _TodayListRowData(
    icon: Icons.bolt_rounded,
    accent: AppColors.primary,
    title: 'CA Shots',
    subtitle: 'Breaking news brief + 1 MCQ based on it.',
    done: false,
    locked: false,
    onTap: () => context.push('/fomo-pulse'),
  );
}

String _warListSubtitle({
  required bool submitted,
  required bool live,
  required bool resultsOpen,
  required List<DailyWarTopicRef> topics,
  required DailyWarPhase phase,
  required bool isGrand,
  required bool weekend,
}) {
  if (weekend) return 'Topics: all from this week.';
  final topicsLine = DailyWarCopy.topicsLine(topics, sep: ' · ');
  if (topicsLine.isNotEmpty) return topicsLine;
  if (submitted) return 'You were there — see your rank';
  if (live) return 'All-India live paper. Join now.';
  if (resultsOpen) return "Last night's paper is up";
  return 'All-India live test · 9 PM';
}

// ── Big Hero Cards ────────────────────────────────────────────────────────────

/// Full-bleed dark hero card matching the design screenshots.
class _BigHeroCard extends StatelessWidget {
  const _BigHeroCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.background,
    required this.ctaColor,
    required this.onTap,
    this.loading = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String ctaLabel;
  final Color background;
  final Color ctaColor;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    // Determine if the background is dark so we can adjust text colors.
    final bgLuminance = background.computeLuminance();
    final isDarkBg = bgLuminance < 0.35;
    final eyebrowColor = isDarkBg ? ctaColor : ctaColor.withValues(alpha: 0.85);
    final titleColor = isDarkBg ? Colors.white : Colors.white;
    final descColor = isDarkBg
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                eyebrow,
                style: AppTextStyles.caption().copyWith(
                  color: eyebrowColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.h1().copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTextStyles.bodySm().copyWith(
                  color: descColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctaColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ctaLabel,
                              style: AppTextStyles.label().copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── War Hero Card ─────────────────────────────────────────────────────────────

class _WarHeroCard extends StatelessWidget {
  const _WarHeroCard({
    required this.submitted,
    required this.topics,
    required this.phase,
    required this.overnight,
    required this.isGrand,
    required this.caughtUp,
    required this.onTap,
  });

  final bool submitted;
  final List<DailyWarTopicRef> topics;
  final DailyWarPhase phase;
  final bool overnight;
  final bool isGrand;
  final bool caughtUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canEnter = phase == DailyWarPhase.liveJoinable;
    final compiling =
        phase == DailyWarPhase.liveLocked ||
        phase == DailyWarPhase.resultsPending;
    final resultsReady = phase == DailyWarPhase.resultsReady;
    final weekend = isGrand || topics.length > 2;
    final warName = DailyWarCopy.eventName(isGrand: isGrand);
    final topicsLine = DailyWarCopy.topicsLine(topics, sep: '\n');
    final tonightBg = isDark
        ? const Color(0xFF0D2818)
        : const Color(0xFF1B4332);

    final String eyebrow;
    final String title;
    final String description;
    final String ctaLabel;
    final Color bg;

    if (submitted) {
      eyebrow = caughtUp
          ? '${DailyWarCopy.eventNameCaps(isGrand: isGrand)} · DAY COMPLETE'
          : DailyWarCopy.eventNameCaps(isGrand: isGrand);
      title = caughtUp
          ? 'Well played tonight'
          : (topicsLine.isNotEmpty ? topicsLine : warName);
      description = caughtUp
          ? 'You\'ve submitted. Rankings close out at 9 PM.'
          : 'You were in the room. The rank is waiting.';
      ctaLabel = 'See how you did';
      bg = isDark ? const Color(0xFF1A3A2A) : const Color(0xFF1B4332);
    } else if (canEnter) {
      eyebrow = 'LIVE · JOIN NOW';
      title = topicsLine.isNotEmpty ? topicsLine : warName;
      description = 'You can still join. Same paper, then the rank.';
      ctaLabel = isGrand ? 'Join the War' : 'Join the Battle';
      bg = tonightBg;
    } else if (compiling) {
      eyebrow = 'RANKS COMPILING';
      title = topicsLine.isNotEmpty ? topicsLine : warName;
      description = 'The paper is closed. Ranks are being compiled.';
      ctaLabel = 'See the paper';
      bg = isDark ? const Color(0xFF2A1A1A) : const Color(0xFF3B1F1F);
    } else if (overnight) {
      eyebrow = '${DailyWarCopy.eventNameCaps(isGrand: isGrand)} · LAST NIGHT';
      title = topicsLine.isNotEmpty ? topicsLine : warName;
      description = "Last night's paper is up if you still want the questions.";
      ctaLabel = 'Open the paper';
      bg = isDark ? const Color(0xFF2A1A1A) : const Color(0xFF3B1F1F);
    } else if (resultsReady) {
      eyebrow = 'RESULTS';
      title = topicsLine.isNotEmpty ? topicsLine : warName;
      description = 'Ranks are up. See how you placed.';
      ctaLabel = 'See results';
      bg = isDark ? const Color(0xFF1A3A2A) : const Color(0xFF1B4332);
    } else if (weekend) {
      final weekBit = topics.isEmpty
          ? 'Week revision'
          : 'Week revision · ${topics.length} topics';
      eyebrow = DailyWarCopy.eventNameCaps(isGrand: isGrand);
      title = 'Saturday at 9 PM';
      description = '$weekBit. Same paper, All-India.';
      ctaLabel = topics.isNotEmpty ? 'See topics' : 'How it works';
      bg = isDark ? DwColors.surface : DwColors.crimsonSoft;
    } else {
      eyebrow = 'TONIGHT';
      final topicTitle = topicsLine.isNotEmpty
          ? topicsLine
          : '${DailyWarCopy.dailyEventName} starts at 9 PM';
      title = topicTitle;
      description = isGrand
          ? 'Static GS week revision. All-India live test, public leaderboard.'
          : 'Static GS paper. All-India live test, public leaderboard.';
      ctaLabel = 'Open';
      bg = tonightBg;
    }

    return _BigHeroCard(
      eyebrow: eyebrow,
      title: title,
      description: description,
      ctaLabel: ctaLabel,
      background: bg,
      ctaColor: submitted || canEnter || (!overnight && !compiling)
          ? AppColors.primary
          : DwColors.crimsonBright,
      onTap: onTap,
    );
  }
}

// ── CA Hero Card ──────────────────────────────────────────────────────────────

class _CaHeroCard extends StatelessWidget {
  const _CaHeroCard({
    required this.paperDate,
    required this.isTodaysPaper,
    required this.completed,
    required this.loading,
    required this.questionsReady,
    required this.onStart,
  });

  final DateTime? paperDate;
  final bool isTodaysPaper;
  final bool completed;
  final bool loading;
  final bool questionsReady;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.infoBgDark : const Color(0xFF0C447C);

    final String eyebrow;
    final String title;
    final String description;
    final String ctaLabel;
    final date = paperDate;
    final dateLabel = date == null
        ? null
        : (isTodaysPaper
              ? "Today's paper"
              : '${DateFormat('d MMM').format(date)} paper');

    if (date == null) {
      eyebrow = 'CURRENT AFFAIRS';
      title = 'Paper quiz';
      description = 'Opens at 6 AM — yesterday\'s news, today\'s questions.';
      ctaLabel = 'Soon';
    } else if (completed) {
      eyebrow = 'CURRENT AFFAIRS';
      title = dateLabel!;
      description = 'Quiz done. Open the explanations if a line still nags.';
      ctaLabel = 'Review your attempt';
    } else if (!questionsReady) {
      eyebrow = 'CURRENT AFFAIRS';
      title = dateLabel!;
      description = 'Questions are being prepared. Check back shortly.';
      ctaLabel = 'Soon';
    } else {
      eyebrow = 'CURRENT AFFAIRS';
      title = dateLabel!;
      description = 'A test of questions from yesterday\'s news.';
      ctaLabel = 'Start the quiz';
    }

    final paperReadyToStart = date != null && questionsReady;
    void handleTap() {
      if (completed || paperReadyToStart) {
        onStart?.call();
        return;
      }
      unawaited(
        showDailyCaUnavailableSheet(
          context: context,
          availableFrom: DailyCaSchedule.nextOpensAt(),
          pendingLive: date != null,
          onSeeHistory: () {
            if (context.mounted) context.push('/daily-ca');
          },
        ),
      );
    }

    return _BigHeroCard(
      eyebrow: eyebrow,
      title: title,
      description: description,
      ctaLabel: ctaLabel,
      background: bg,
      ctaColor: AppColors.primary,
      loading: loading,
      onTap: handleTap,
    );
  }
}

// ── Practice Hero Card ────────────────────────────────────────────────────────

class _PracticeHeroCard extends StatelessWidget {
  const _PracticeHeroCard({
    required this.isSunday,
    required this.mistakeCount,
    this.wrongCount = 0,
    this.bookmarkCount = 0,
    required this.completed,
    required this.loading,
    required this.onStart,
  });

  final bool isSunday;
  final int mistakeCount;
  final int wrongCount;
  final int bookmarkCount;
  final bool completed;
  final bool loading;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.primaryDeep.withValues(alpha: 0.5)
        : AppColors.primaryDark;

    final String eyebrow;
    final String title;
    final String description;
    final String ctaLabel;

    if (isSunday) {
      if (completed) {
        eyebrow = 'WEEK REVIEW · DONE';
        title = 'Week review done';
        description =
            'You\'ve gone through last week\'s mistakes. Streak intact.';
        ctaLabel = 'See results';
      } else if (mistakeCount <= 0) {
        eyebrow = 'WEEK REVIEW · EMPTY';
        title = 'No mistakes this week';
        description = 'No mistakes from last week — you\'re clean.';
        ctaLabel = 'Quick practice instead';
      } else {
        eyebrow = 'WEEK REVIEW';
        title = 'Review last week\'s mistakes';
        description = '$mistakeCount questions where you slipped last week.';
        ctaLabel = 'Start review';
      }
    } else {
      eyebrow = 'REVISION QUEUE';
      title = 'Revision queue';
      final counts = DailyRevision.countsLine(
        missed: wrongCount,
        saved: bookmarkCount,
      );
      if (completed) {
        description = counts == DailyRevision.emptyQueueLine
            ? 'Today\'s revision is in the books.'
            : '$counts. Open again if you want another set.';
        ctaLabel = 'Open again';
      } else if (wrongCount <= 0 && bookmarkCount <= 0) {
        description =
            'Questions you get wrong or bookmark land here. Then take a short random test.';
        ctaLabel = 'Empty';
      } else {
        description = '$counts. A short random test from either pool.';
        ctaLabel = 'Open';
      }
    }

    return _BigHeroCard(
      eyebrow: eyebrow,
      title: title,
      description: description,
      ctaLabel: ctaLabel,
      background: bg,
      ctaColor: AppColors.primary,
      loading: loading,
      onTap: onStart,
    );
  }
}

class _HeroLoadingCard extends StatelessWidget {
  const _HeroLoadingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}

/// TEMP debug catalog — remove with [_HeroPreviewBar].
enum _HeroPreviewId {
  live,
  caSoon,
  caPreparing,
  caReady,
  caDone,
  practiceOpen,
  practiceDone,
  practiceEmpty,
  warClock,
  warLastNight,
  warCaughtUp,
}

extension _HeroPreviewIdX on _HeroPreviewId {
  static const _itemOrder = <String>['Live', 'CA', 'Practice', 'War'];

  static const _statesByItem = <String, List<_HeroPreviewId>>{
    'Live': [_HeroPreviewId.live],
    'CA': [
      _HeroPreviewId.caSoon,
      _HeroPreviewId.caPreparing,
      _HeroPreviewId.caReady,
      _HeroPreviewId.caDone,
    ],
    'Practice': [
      _HeroPreviewId.practiceOpen,
      _HeroPreviewId.practiceDone,
      _HeroPreviewId.practiceEmpty,
    ],
    'War': [
      _HeroPreviewId.warClock,
      _HeroPreviewId.warLastNight,
      _HeroPreviewId.warCaughtUp,
    ],
  };

  String get itemLabel => switch (this) {
    _HeroPreviewId.live => 'Live',
    _HeroPreviewId.caSoon ||
    _HeroPreviewId.caPreparing ||
    _HeroPreviewId.caReady ||
    _HeroPreviewId.caDone => 'CA',
    _HeroPreviewId.practiceOpen ||
    _HeroPreviewId.practiceDone ||
    _HeroPreviewId.practiceEmpty => 'Practice',
    _HeroPreviewId.warClock ||
    _HeroPreviewId.warLastNight ||
    _HeroPreviewId.warCaughtUp => 'War',
  };

  String get stateLabel => switch (this) {
    _HeroPreviewId.live => 'clock',
    _HeroPreviewId.caSoon => 'Opens 6 AM',
    _HeroPreviewId.caPreparing => 'Preparing',
    _HeroPreviewId.caReady => 'Start quiz',
    _HeroPreviewId.caDone => 'Open answers',
    _HeroPreviewId.practiceOpen => 'Open',
    _HeroPreviewId.practiceDone => 'Done',
    _HeroPreviewId.practiceEmpty => 'Empty → War',
    _HeroPreviewId.warClock => 'Clock',
    _HeroPreviewId.warLastNight => 'Last night',
    _HeroPreviewId.warCaughtUp => 'Caught up',
  };

  _HeroPreviewId get nextItem {
    final i = _itemOrder.indexOf(itemLabel);
    final next = _itemOrder[(i + 1) % _itemOrder.length];
    return _statesByItem[next]!.first;
  }

  _HeroPreviewId get nextState {
    final states = _statesByItem[itemLabel]!;
    if (states.length == 1) return this;
    final i = states.indexOf(this);
    return states[(i + 1) % states.length];
  }
}

class _HeroPreviewBar extends StatelessWidget {
  const _HeroPreviewBar({
    required this.preview,
    required this.onCycleItem,
    required this.onCycleState,
  });

  final _HeroPreviewId preview;
  final VoidCallback onCycleItem;
  final VoidCallback onCycleState;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3C4),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Text(
              'TEMP',
              style: AppTextStyles.caption().copyWith(
                color: const Color(0xFF7A5A00),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _HeroPreviewChip(
                    label: 'Item: ${preview.itemLabel}',
                    onTap: onCycleItem,
                  ),
                  _HeroPreviewChip(
                    label: 'State: ${preview.stateLabel}',
                    onTap: onCycleState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPreviewChip extends StatelessWidget {
  const _HeroPreviewChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8C547),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: const Color(0xFF3D2E00),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
