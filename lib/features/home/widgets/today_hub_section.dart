import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../community/providers/open_challenge_providers.dart';
import '../../community/widgets/open_challenge_what_is_sheet.dart';
import '../providers/auth_providers.dart';
import '../../daily_war/domain/daily_war_phase.dart';
import '../../daily_war/domain/daily_war_phase_resolver.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../../daily_war/providers/server_clock_provider.dart';
import '../../../core/constants/daily_drill_constants.dart';
import '../domain/activation_journey_constants.dart';
import '../domain/daily_revision.dart';
import '../domain/daily_rituals.dart';
import '../domain/daily_streak_service.dart';
import '../domain/start_daily_drill.dart';
import '../domain/today_hero.dart';
import '../providers/daily_drill_provider.dart';
import '../providers/sunday_week_review_provider.dart';
import '../providers/today_hub_provider.dart';
import '../providers/today_hero_intent_provider.dart';
import '../providers/home_activation_journey_provider.dart';
import 'activation_journey_card.dart';
import 'daily_revision_choice_sheet.dart';
import 'daily_rituals_intro_sheet.dart';
import '../../../l10n/l10n.dart';

/// Daily ritual on home: CA test hero until first submit, else Daily Drill,
/// plus a context.l10n.activationKeepGoing list (CA Shots, Current Affairs, Open Challenge,
/// Danger Zone). Static War is mounted separately on Home.
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
    final intentListenable = useListenable(TodayHeroIntentStore.notifier);
    final intent = intentListenable.value;
    final hubDay = TodayHero.hubDate(ist);
    final intentExpired = intent != null && intent.hubDate != hubDay;
    final intentSlotDone =
        intent != null &&
        TodayHero.statusOf(slots, intent.slot) == TodaySlotStatus.done;
    useEffect(() {
      if (intent == null) return null;
      if (!intentExpired && !intentSlotDone) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        TodayHeroIntentStore.clear();
      });
      return null;
    }, [intent, intentExpired, intentSlotDone]);
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

    final launchingDrill = useState(false);

    void openDailyCaHub() {
      unawaited(maybeLogPostDemoExplore(ref, surface: 'daily_ca'));
      context.push('/daily-ca');
    }

    Future<void> openDrill({required String source}) async {
      if (launchingDrill.value) return;
      launchingDrill.value = true;
      try {
        final drill = await ref.read(dailyDrillProvider.future);
        if (!context.mounted || drill == null) return;
        unawaited(maybeLogPostDemoExplore(ref, surface: 'daily_drill'));
        if (drill.hasAnyPool) {
          await showDailyRevisionChoiceSheet(
            context: context,
            ref: ref,
            source: source,
          );
          return;
        }
        await startDailyDrill(
          context: context,
          ref: ref,
          subject: DailyDrillConstants.subjectForHubDay(hubDay),
          source: source,
          completedToday: drill.completedToday,
        );
      } finally {
        launchingDrill.value = false;
      }
    }

    // ── Keep going list — always the same set, independent of the hero ─────

    final openedRituals =
        ref.watch(dailyRitualsOpenedProvider).asData?.value ?? const {};

    List<_TodayListRowData> buildListRows() {
      final rows = <_TodayListRowData>[];

      if (data.caShotsEnabled) {
        rows.add(
          _caShotsListRow(
            context,
            showNew: !openedRituals.contains(DailyRitualIds.caShots),
            onTap: () {
              unawaited(maybeLogPostDemoExplore(ref, surface: 'ca_shot'));
              context.push('/ca-shot');
            },
          ),
        );
      }
      if (data.caEnabled) {
        final caLive = data.paperLive && !data.paperCompleted;
        rows.add(
          _TodayListRowData(
            icon: Icons.article_outlined,
            accent: AppColors.info,
            title: 'Daily Current Affairs Test',
            subtitle: caLive
                ? context.l10n.todayCaLive
                : !data.paperCompleted
                ? context.l10n.todayCaNotDone
                : data.paperResultsOpened
                ? context.l10n.todayDone
                : context.l10n.todayQuizDoneOpenAnswers,
            done: data.paperCompleted && data.paperResultsOpened,
            locked: false,
            showNew: !caLive && !openedRituals.contains(DailyRitualIds.dailyCa),
            showLive: caLive,
            onTap: openDailyCaHub,
          ),
        );
      }

      final communityOn =
          ref.watch(communityTabRemoteEnabledProvider).asData?.value ?? false;
      if (communityOn) {
        final untried =
            ref.watch(homeOpenChallengesProvider).asData?.value ?? const [];
        // The list is cached for the session, so a challenge can hit its 24h
        // expiry while the app stays open. Re-check at render, not at fetch.
        final now = DateTime.now();
        final live = [
          for (final c in untried)
            if (c.liveUntil == null || c.liveUntil!.isAfter(now)) c,
        ];
        if (live.isNotEmpty) {
          final challenge = live.first;
          final poster = _challengerFirstName(challenge.postedByName);
          // The subject rides in the subtitle, which gets two lines — so the
          // part users actually choose on is never the part that ellipsizes.
          final mixed = challenge.subject.trim().toLowerCase() == 'misc';
          // 'their' only refers to someone when the title names them.
          final who = poster == null ? 'top' : 'poster';
          final goal = mixed
              ? context.l10n.homeChallengeGoalMixed(who, challenge.topScore)
              : context.l10n.homeChallengeGoalSubject(
                  who,
                  challenge.topScore,
                  openChallengeSubjectTitle(challenge.subject),
                );
          final others = live.length - 1;
          rows.add(
            _TodayListRowData(
              icon: Icons.emoji_events_outlined,
              accent: AppColors.primary,
              title: poster == null
                  ? 'Open challenge'
                  : context.l10n.homeOpenChallengeBy(poster),
              subtitle: others > 0
                  ? context.l10n.homeGoalOthersLive(goal, others)
                  : goal,
              subtitleMaxLines: 2,
              done: false,
              locked: false,
              showLive: true,
              onTap: () async {
                unawaited(
                  maybeLogPostDemoExplore(ref, surface: 'open_challenge'),
                );
                final user = ref.read(authStateChangesProvider).asData?.value;
                if (!AuthSession.isAccountSignedIn(user)) {
                  final wantsSignIn = await showOpenChallengeWhatIsSheet(
                    context,
                    showSignInCta: true,
                  );
                  if (!context.mounted) return;
                  if (wantsSignIn != true) return;
                  final signedIn = await ensureAccountSignedIn(
                    context: context,
                    ref: ref,
                    reason: context.l10n.todaySignInOpenChallenge,
                  );
                  if (!context.mounted || !signedIn) return;
                }
                // Land on the list either way so the rest stay discoverable;
                // the featured one is marked and scrolled to on arrival.
                context.go(
                  '/community?tab=open_challenge&highlight=${challenge.id}',
                );
              },
            ),
          );
        }
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
              ? context.l10n.todayDangerUnlocked
              : scored == null
              ? context.l10n.homeDangerLocked(unlockAt)
              : context.l10n.homeDangerLockedProgress(unlockAt, scored),
          subtitleMaxLines: 2,
          done: false,
          locked: !unlocked,
          onTap: unlocked
              ? () {
                  unawaited(
                    maybeLogPostDemoExplore(ref, surface: 'danger_zone'),
                  );
                  context.push('/weak-areas/traps');
                }
              : null,
        ),
      );

      return rows;
    }

    final listRows = buildListRows();

    if (!data.caEnabled &&
        !data.caShotsEnabled &&
        !data.warEnabled &&
        !data.staticAvailable) {
      return const SizedBox.shrink();
    }

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // START HERE wins; else Daily CA until first submit (all day); else drill.
    final journey = activationJourney;
    final after6Am = ist.hour >= TodayHero.paperHourIst;
    final caHero =
        data.caEnabled && after6Am && data.paperLive && !data.paperCompleted;
    final Widget heroWidget;
    if (activationJourneyLoading) {
      heroWidget = const _HeroLoadingCard();
    } else if (journey != null && journey.shouldShowChecklist) {
      heroWidget = ActivationJourneyCard(state: journey);
    } else if (caHero) {
      heroWidget = _CaTestHeroCard(
        checking: data.paperChecking,
        onOpen: openDailyCaHub,
      );
    } else {
      heroWidget = _PracticeHeroCard(
        isSunday: false,
        mistakeCount: 0,
        wrongCount: data.revisionWrongCount,
        bookmarkCount: data.revisionBookmarkCount,
        completed: data.staticCompleted,
        loading: launchingDrill.value || !data.staticAvailable,
        subjectDisplay: DailyDrillConstants.subjectForHubDay(hubDay),
        onStart: data.staticAvailable
            ? () => unawaited(openDrill(source: 'today_hub_hero'))
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Hero card ──────────────────────────────────────────────────────
        heroWidget,

        // ── TODAY list ─────────────────────────────────────────────────────
        if (listRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                context.l10n.activationKeepGoing,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (data.caShotsEnabled || data.caEnabled || data.warEnabled)
                InkWell(
                  onTap: () => unawaited(
                    showDailyRitualsIntroSheet(context, ref, fromHelp: true),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.todayWhatIsThis,
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
    this.showNew = false,
    this.showLive = false,
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
  final bool showNew;
  final bool showLive;
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label().copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (data.showLive && !data.done) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const _LiveBadge(),
                          ] else if (data.showNew && !data.done) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _NewBadge(accent: data.accent),
                          ],
                        ],
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

/// Placeholders written when a challenge has no real creator profile. Naming
/// one of these reads as a bug rather than a person.
const _openChallengePlaceholderNames = {'warrior', 'upsc warrior'};

/// First name of an open-challenge poster, or null when there is nothing worth
/// naming. Past ten characters the 'Open challenge by …' title outgrows the one
/// line it gets, so a long name is dropped rather than shown clipped.
String? _challengerFirstName(String postedByName) {
  final trimmed = postedByName.trim();
  if (trimmed.isEmpty) return null;
  if (_openChallengePlaceholderNames.contains(trimmed.toLowerCase())) {
    return null;
  }
  final first = trimmed.split(RegExp(r'\s+')).first;
  return first.length > 10 ? null : first;
}

_TodayListRowData _caShotsListRow(
  BuildContext context, {
  required bool showNew,
  required VoidCallback onTap,
}) {
  return _TodayListRowData(
    icon: Icons.bolt_rounded,
    accent: AppColors.primary,
    title: 'CA Shots',
    subtitle: context.l10n.todayCaShotSubtitle,
    done: false,
    locked: false,
    showNew: showNew,
    onTap: onTap,
  );
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'NEW',
        style: AppTextStyles.caption().copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pulse.stop();
      _pulse.value = 0.55;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = reduceMotion ? 0.55 : _pulse.value;
        final glow = 0.18 + (t * 0.42);
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 2, 7, 2),
          decoration: BoxDecoration(
            color: AppColors.wrong.withValues(alpha: 0.12 + (t * 0.10)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.wrong.withValues(alpha: glow),
                blurRadius: 6 + (t * 5),
                spreadRadius: t * 0.6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.wrong,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.wrong,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
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

// ── Practice Hero Card ────────────────────────────────────────────────────────

class _CaTestHeroCard extends StatelessWidget {
  const _CaTestHeroCard({required this.checking, required this.onOpen});

  final bool checking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.infoBgDark : AppColors.infoText;
    return _BigHeroCard(
      eyebrow: 'DAILY CURRENT AFFAIRS',
      title: context.l10n.todayPaperQuizTitle,
      description: context.l10n.todayPaperQuizBody,
      ctaLabel: context.l10n.todayOpenPaper,
      background: bg,
      ctaColor: AppColors.primary,
      loading: checking,
      onTap: onOpen,
    );
  }
}

class _PracticeHeroCard extends StatelessWidget {
  const _PracticeHeroCard({
    required this.isSunday,
    required this.mistakeCount,
    this.wrongCount = 0,
    this.bookmarkCount = 0,
    required this.completed,
    required this.loading,
    required this.onStart,
    this.subjectDisplay = '',
  });

  final bool isSunday;
  final int mistakeCount;
  final int wrongCount;
  final int bookmarkCount;
  final bool completed;
  final bool loading;
  final VoidCallback? onStart;
  final String subjectDisplay;

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
        title = context.l10n.todayWeekDone;
        description = context.l10n.todayWeekDoneBody;
        ctaLabel = context.l10n.todaySeeResults;
      } else if (mistakeCount <= 0) {
        eyebrow = 'WEEK REVIEW · EMPTY';
        title = context.l10n.todayWeekEmpty;
        description = context.l10n.todayWeekEmptyBody;
        ctaLabel = context.l10n.todayQuickPracticeInstead;
      } else {
        eyebrow = 'WEEK REVIEW';
        title = context.l10n.todayWeekReviewTitle;
        description = context.l10n.homeWeekReviewCount(mistakeCount);
        ctaLabel = context.l10n.todayStartReview;
      }
    } else {
      eyebrow = 'DAILY DRILL';
      title = completed
          ? context.l10n.todayDrillDone
          : context.l10n.todayDrillTitle;
      final counts = DailyRevision.countsLine(
        missed: wrongCount,
        saved: bookmarkCount,
      );
      final subjectBit = subjectDisplay.isEmpty
          ? context.l10n.todayDrillBody
          : context.l10n.homeDrillSubjectBit(subjectDisplay);
      if (completed) {
        description = counts == DailyRevision.emptyQueueLine
            ? context.l10n.todayDrillInBooks
            : context.l10n.homeDrillOpenAgain(counts);
        ctaLabel = context.l10n.todayOpenAgain;
      } else if (wrongCount <= 0 && bookmarkCount <= 0) {
        description = subjectBit;
        ctaLabel = context.l10n.commonStart;
      } else {
        description = context.l10n.homeDrillShortSet(counts);
        ctaLabel = context.l10n.commonStart;
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
