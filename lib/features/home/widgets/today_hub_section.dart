import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/domain/open_daily_ca_test.dart';
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
import '../domain/daily_streak_service.dart';
import '../domain/start_sunday_week_review.dart';
import '../domain/today_hero.dart';
import '../providers/sunday_week_review_provider.dart';
import '../providers/today_hub_provider.dart';
import '../providers/home_activation_journey_provider.dart';
import 'activation_journey_card.dart';
import 'daily_revision_choice_sheet.dart';

/// Daily ritual on home: one full-width hero card + a flat "TODAY" activity list.
///
/// The hero card changes based on time of day and which activity is most urgent.
/// All other activities appear as list rows beneath the hero.
class TodayHubSection extends HookConsumerWidget {
  const TodayHubSection({
    super.key,
    this.forceWarCollapsed = false,
    this.activationJourney,
  });

  final bool forceWarCollapsed;
  final HomeActivationJourneyState? activationJourney;

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

    // ── War phase helpers ────────────────────────────────────────────────────
    final warLive =
        warPhase == DailyWarPhase.lobby ||
        warPhase == DailyWarPhase.liveJoinable ||
        warPhase == DailyWarPhase.liveLocked;
    final warResultsOpen =
        overnight ||
        warPhase == DailyWarPhase.resultsPending ||
        warPhase == DailyWarPhase.resultsReady;
    final isGrand = hubWarDoc?.isGrand == true;
    final weekend = isGrand || warTopics.length > 2;
    final warName = isGrand ? 'Grand War' : 'Daily War';

    // ── Hero card content ────────────────────────────────────────────────────

    // Returns the hero card widget for the given hero slot.
    Widget buildHeroCard() {
      switch (hero) {
        case TodaySlotId.war:
          if (!data.warEnabled || sundayHub) break;
          // Use full DailyWarHomeCard only when it's the true live/urgent hero.
          final useFullWar =
              !overnight && !pick.caughtUp && !forceWarCollapsed;
          if (useFullWar && warLive) {
            return DailyWarHomeCard(forceCollapsed: false);
          }
          return _WarHeroCard(
            dateId: hubWarDateId,
            submitted: hubWarSubmitted,
            topics: warTopics,
            phase: warPhase,
            overnight: overnight,
            showNow: !pick.caughtUp,
            isGrand: isGrand,
            caughtUp: pick.caughtUp,
          );

        case TodaySlotId.current:
          if (!data.caEnabled) break;
          return _CaHeroCard(
            paperDate: data.paperDate,
            isTodaysPaper: data.paperDate != null &&
                DailyCaSchedule.isTodaysPaper(
                  data.paperDate!,
                  referenceIst: ist,
                ),
            completed: data.paperCompleted,
            loading: launchingPaper.value || data.paperChecking,
            questionsReady: data.paperLive,
            emphasized: !pick.caughtUp,
            onStart: data.paperLive ? openPaper : null,
          );

        case TodaySlotId.practice:
          if (sundayHub) {
            if (weekReview == null) break;
            return _PracticeHeroCard(
              isSunday: true,
              mistakeCount: weekReview.uuids.length,
              completed: weekReview.completedToday,
              loading: launchingReview.value,
              emphasized: !pick.caughtUp,
              caughtUp: pick.caughtUp,
              onStart: openWeekReview,
            );
          }
          if (!data.staticAvailable) break;
          return _PracticeHeroCard(
            isSunday: false,
            mistakeCount: 0,
            completed: data.staticCompleted,
            loading: false,
            emphasized: !pick.caughtUp,
            caughtUp: pick.caughtUp,
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

      // Fallback: full-day done card
      return _DayCompleteHeroCard(slots: slots);
    }

    // ── TODAY list rows ──────────────────────────────────────────────────────

    final allDisplayIds = TodayHero.displayOrder(
      hero,
      warEvening: warEvening,
      caughtUp: pick.caughtUp,
    );
    final companionIds = allDisplayIds.where((id) => id != hero).toList();

    List<_TodayListRowData> buildListRows() {
      final rows = <_TodayListRowData>[];

      for (final id in companionIds) {
        switch (id) {
          case TodaySlotId.current:
            if (!data.caEnabled) continue;
            // Daily CA test row
            rows.add(_TodayListRowData(
              icon: Icons.article_outlined,
              accent: AppColors.info,
              title: 'Daily Current Affairs Test',
              subtitle: data.paperCompleted
                  ? 'Done today'
                  : "Current affairs test from yesterday's news.",
              done: data.paperCompleted,
              locked: false,
              onTap: data.paperLive ? openPaper : null,
              loading: launchingPaper.value || data.paperChecking,
            ));
            rows.add(_caShotsListRow(context));

          case TodaySlotId.practice:
            if (sundayHub) {
              if (weekReview == null) continue;
              rows.add(_TodayListRowData(
                icon: Icons.history_edu_rounded,
                accent: AppColors.warning,
                title: 'Week Review',
                subtitle: weekReview.completedToday
                    ? 'Done today'
                    : '${weekReview.uuids.length} mistakes to revisit',
                done: weekReview.completedToday,
                locked: false,
                onTap: weekReview.uuids.isNotEmpty ? openWeekReview : null,
                loading: launchingReview.value,
              ));
            } else {
              if (!data.staticAvailable) continue;
              rows.add(_TodayListRowData(
                icon: Icons.fitness_center_rounded,
                accent: AppColors.primary,
                title: 'Static War',
                subtitle: data.staticCompleted
                    ? 'Done today'
                    : '10 questions, timed, your subjects',
                done: data.staticCompleted,
                locked: false,
                onTap: () {
                  unawaited(
                    showDailyRevisionChoiceSheet(
                      context: context,
                      ref: ref,
                      source: 'today_hub_list',
                    ),
                  );
                },
              ));
            }

          case TodaySlotId.war:
            if (!data.warEnabled || sundayHub) continue;
            final warTitle = warLive
                ? (isGrand ? 'Grand War — LIVE' : 'Daily War — LIVE')
                : warResultsOpen
                ? 'Daily War — last night'
                : warName;
            final warSubtitle = _warListSubtitle(
              submitted: hubWarSubmitted,
              live: warLive,
              resultsOpen: warResultsOpen,
              topics: warTopics,
              phase: warPhase,
              isGrand: isGrand,
              weekend: weekend,
            );
            rows.add(_TodayListRowData(
              icon: Icons.shield_outlined,
              accent: DwColors.crimsonBright,
              title: warTitle,
              subtitle: warSubtitle,
              done: hubWarSubmitted,
              locked: false,
              onTap: () {
                if (warLive) {
                  context.push('/daily-war');
                  return;
                }
                if (hubWarSubmitted || warResultsOpen) {
                  if (hubWarDateId.isEmpty) return;
                  context.push('/daily-war/history/$hubWarDateId');
                  return;
                }
                if (weekend && warTopics.isNotEmpty) {
                  unawaited(
                    showDailyWarTopicsSheet(
                      context: context,
                      topics: warTopics,
                    ),
                  );
                  return;
                }
                unawaited(
                  showDailyWarExplainerSheet(
                    context: context,
                    topics: warTopics,
                    isGrand: isGrand,
                  ),
                );
              },
            ));
        }
      }

      // CA Shots sits under Daily CA; if CA is the hero, still show it first.
      if (hero == TodaySlotId.current && data.caEnabled) {
        rows.insert(0, _caShotsListRow(context));
      }

      // Always show Danger Zone at the end
      rows.add(_TodayListRowData(
        icon: Icons.lock_outline_rounded,
        accent: AppColors.wrong,
        title: 'Danger Zone',
        subtitle: 'Unlocks at 50 questions — 0/50 so far',
        done: false,
        locked: true,
        onTap: () => context.push('/weak-areas/traps'),
      ));

      return rows;
    }

    final listRows = buildListRows();

    if (!data.caEnabled && !data.warEnabled && !data.staticAvailable) {
      return const SizedBox.shrink();
    }

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // When activation checklist is active, show it as the hero instead.
    final journey = activationJourney;
    final heroWidget = (journey != null && journey.shouldShowChecklist)
        ? ActivationJourneyCard(state: journey)
        : buildHeroCard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Hero card ──────────────────────────────────────────────────────
        heroWidget,

        // ── TODAY list ─────────────────────────────────────────────────────
        if (listRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'TODAY',
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
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
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
    final accent =
        data.locked ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : data.accent;
    final fg =
        data.locked ? scheme.onSurfaceVariant : scheme.onSurface;

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
                        : accent.withValues(
                            alpha: isDark ? 0.18 : 0.12,
                          ),
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
                        maxLines: 1,
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
    this.footer,
    this.loading = false,
    this.done = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String ctaLabel;
  final Color background;
  final Color ctaColor;
  final VoidCallback? onTap;
  final String? footer;
  final bool loading;
  final bool done;

  @override
  Widget build(BuildContext context) {
    // Determine if the background is dark so we can adjust text colors.
    final bgLuminance = background.computeLuminance();
    final isDarkBg = bgLuminance < 0.35;
    final eyebrowColor =
        isDarkBg ? ctaColor : ctaColor.withValues(alpha: 0.85);
    final titleColor = isDarkBg ? Colors.white : Colors.white;
    final descColor =
        isDarkBg ? Colors.white.withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.72);
    final footerColor =
        isDarkBg ? Colors.white.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.55);

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
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  footer!,
                  style: AppTextStyles.caption().copyWith(
                    color: footerColor,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
    required this.dateId,
    required this.submitted,
    required this.topics,
    required this.phase,
    required this.overnight,
    required this.showNow,
    required this.isGrand,
    required this.caughtUp,
  });

  final String dateId;
  final bool submitted;
  final List<DailyWarTopicRef> topics;
  final DailyWarPhase phase;
  final bool overnight;
  final bool showNow;
  final bool isGrand;
  final bool caughtUp;

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
    final weekend = isGrand || topics.length > 2;
    final warName = isGrand ? 'Grand War' : 'Daily War';
    final topicsLine = DailyWarCopy.topicsLine(topics, sep: '\n');

    final String eyebrow;
    final String title;
    final String description;
    final String ctaLabel;
    final Color bg;

    if (submitted) {
      eyebrow = caughtUp ? 'DAY COMPLETE' : 'DAILY WAR';
      title = caughtUp ? 'Well played tonight' : (topicsLine.isNotEmpty ? topicsLine : warName);
      description = caughtUp
          ? 'You\'ve submitted. Rankings close out at 9 PM.'
          : 'You were in the room. The rank is waiting.';
      ctaLabel = 'See how you did';
      bg = isDark ? const Color(0xFF1A3A2A) : const Color(0xFF1B4332);
    } else if (live) {
      eyebrow = 'LIVE NOW';
      title = topicsLine.isNotEmpty ? topicsLine : warName;
      description = 'All-India live paper. Same questions, then the rank.';
      ctaLabel = 'Join the War';
      bg = isDark ? DwColors.surface : DwColors.crimsonSoft;
    } else if (resultsOpen) {
      eyebrow = 'LAST NIGHT';
      title = topicsLine.isNotEmpty ? topicsLine : warName;
      description = "Last night's paper is up if you still want the questions.";
      ctaLabel = 'Open the paper';
      bg = isDark ? const Color(0xFF2A1A1A) : const Color(0xFF3B1F1F);
    } else if (weekend) {
      final weekBit = topics.isEmpty
          ? 'Week revision'
          : 'Week revision · ${topics.length} topics';
      eyebrow = isGrand ? 'GRAND WAR' : 'DAILY WAR';
      title = 'Saturday at 9 PM';
      description = '$weekBit. Same paper, All-India.';
      ctaLabel = topics.isNotEmpty ? 'See topics' : 'How it works';
      bg = isDark ? DwColors.surface : DwColors.crimsonSoft;
    } else {
      eyebrow = 'TONIGHT';
      final topicTitle = topicsLine.isNotEmpty ? topicsLine : 'Daily War starts in';
      title = topicTitle;
      description = 'Local Government — Union Executive. All-India live test, public leaderboard.';
      ctaLabel = 'Set a reminder';
      bg = isDark ? const Color(0xFF0D2818) : const Color(0xFF1B4332);
    }

    return _BigHeroCard(
      eyebrow: eyebrow,
      title: title,
      description: description,
      ctaLabel: ctaLabel,
      background: bg,
      ctaColor: submitted || (!live && !resultsOpen)
          ? AppColors.primary
          : DwColors.crimsonBright,
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
    required this.emphasized,
    required this.onStart,
  });

  final DateTime? paperDate;
  final bool isTodaysPaper;
  final bool completed;
  final bool loading;
  final bool questionsReady;
  final bool emphasized;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.infoBgDark : const Color(0xFF0C447C);

    final String eyebrow;
    final String title;
    final String description;
    final String ctaLabel;

    if (completed) {
      eyebrow = 'CURRENT AFFAIRS';
      title = 'Today\'s brief done';
      description = 'You\'ve read today\'s CA brief and answered the question.';
      ctaLabel = 'Revise again';
    } else if (!questionsReady) {
      eyebrow = 'CURRENT AFFAIRS';
      title = 'Today\'s brief coming soon';
      description = 'The daily CA brief will be ready shortly. Check back in a few minutes.';
      ctaLabel = 'Check back later';
    } else {
      eyebrow = 'START HERE';
      title = "Today's current affairs brief";
      description = 'Read the brief, answer the MCQ — done in under 3 minutes.';
      ctaLabel = 'Read the brief';
    }

    return _BigHeroCard(
      eyebrow: eyebrow,
      title: title,
      description: description,
      ctaLabel: ctaLabel,
      background: bg,
      ctaColor: AppColors.primary,
      loading: loading,
      done: completed,
      onTap: onStart,
    );
  }
}

// ── Practice Hero Card ────────────────────────────────────────────────────────

class _PracticeHeroCard extends StatelessWidget {
  const _PracticeHeroCard({
    required this.isSunday,
    required this.mistakeCount,
    required this.completed,
    required this.loading,
    required this.emphasized,
    required this.caughtUp,
    required this.onStart,
  });

  final bool isSunday;
  final int mistakeCount;
  final bool completed;
  final bool loading;
  final bool emphasized;
  final bool caughtUp;
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
      eyebrow = 'SUNDAY REVIEW';
      if (completed) {
        title = 'Week review done';
        description = 'You\'ve gone through last week\'s mistakes. Streak intact.';
        ctaLabel = 'See results';
      } else {
        title = 'Review last week\'s mistakes';
        description = mistakeCount > 0
            ? '$mistakeCount questions where you slipped last week.'
            : 'No mistakes from last week — you\'re clean.';
        ctaLabel = mistakeCount > 0 ? 'Start review' : 'Quick practice instead';
      }
    } else {
      eyebrow = 'THIS AFTERNOON';
      if (completed) {
        title = 'Static War done';
        description = 'Today\'s drill is in the books. Keep it up.';
        ctaLabel = 'See results';
      } else {
        title = 'Static War';
        description = '10 questions, timed, your subjects. Sharpen before tonight.';
        ctaLabel = 'Start the drill';
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
      done: completed,
      onTap: onStart,
    );
  }
}

// ── Day Complete Hero Card ────────────────────────────────────────────────────

class _DayCompleteHeroCard extends StatelessWidget {
  const _DayCompleteHeroCard({required this.slots});

  final List<TodaySlot> slots;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D3B22) : const Color(0xFF1B4332);

    final doneCount = slots.where((s) => s.isDone).length;
    final availableCount = slots.where((s) => !s.isRest).length;

    return _BigHeroCard(
      eyebrow: 'DAY COMPLETE',
      title: 'All done for today',
      description: 'You\'ve completed $doneCount of $availableCount activities. Rankings close at 9 PM.',
      ctaLabel: 'See tonight\'s results',
      background: bg,
      ctaColor: AppColors.primary,
      onTap: null,
      footer: '🔥 Streak intact · Next war in 15h',
    );
  }
}
