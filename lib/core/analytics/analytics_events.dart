// Analytics event catalog: each class maps to a Firebase/GA4
// event in [FirebaseAnalyticsSink]. The doc comment for each class lists the
// **meaning**, **when it is emitted**, and the **GA4 name + parameters** so
// product and data teams can read one file without spelunking the sink.
//
// ## Platform & analytics console (not emitted from this app)
// * **Install counts, DAU / WAU / MAU, stickiness, retention (D1/D7/…), session
//   time, user paths** — use **Google Analytics 4** Active users + (optional)
//   **BigQuery** export; `first_open` and engagement are often automatic.
//   Custom app opens: [AppOpenedEvent] (`app_opened`). Daily War attempters:
//   [DailyWarAttemptedEvent] (`daily_war_attempted`).
// * **Play Store install conversion, organic vs paid source, CPI, campaign
//   UTM** — use **Play Console** + **Google Play Install Referrer** (or
//   Campaign URL on first launch) when you run ads; this codebase does not
//   set install referrer.
// * **“Where they leave / return”** — screen funnels in GA4, or BigQuery
//   joins; [ScreenViewedEvent] gives named routes; [AppNotificationOpenEvent]
//   flags return via push.
//
// Naming: [AnalyticsEvent] is the Dart name; the GA4 `logEvent` `name` is
// always snake_case, defined next to the matching `case` in
// [FirebaseAnalyticsSink.send]. User id is added in the sink when logged in.

/// Top-level [AnalyticsEvent] for type-safe [AnalyticsService.track] calls.
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

// ── App lifecycle & sessions ────────────────────────────────────────────

/// **App cold start (process launch).** Logged once when the root [MaterialApp]
/// mounts, not on every return from the background. Use with session events
/// to reason about restarts.
///
/// **GA4:** `app_opened` with `entry_source` (`organic` | `push` | `deep_link`)
/// and optional `entry_detail` (e.g. notification kind).
final class AppOpenedEvent extends AnalyticsEvent {
  const AppOpenedEvent({
    this.entrySource = 'organic',
    this.entryDetail,
  });

  final String entrySource;
  final String? entryDetail;
}

/// **User brought the app to the foreground** (e.g. resumed from home screen or
/// after unlocking the phone). Pairs with [SessionEndedEvent] for rough
/// in-app session length.
///
/// **GA4:** `session_started` with `entry_source` (`organic` | `push` |
/// `deep_link`) and optional `entry_detail`.
/// **Note:** Distinct from GA4’s automatic “session”; this is a custom event name.
final class SessionStartedEvent extends AnalyticsEvent {
  const SessionStartedEvent({
    this.entrySource = 'organic',
    this.entryDetail,
  });

  final String entrySource;
  final String? entryDetail;
}

/// **User left the app** (switched app or backgrounded). Emitted on pause/detach.
///
/// **GA4:** `session_ended` (no custom parameters).
final class SessionEndedEvent extends AnalyticsEvent {
  const SessionEndedEvent();
}

// ── Navigation (automatic) ─────────────────────────────────────────────

/// **User navigated to a named GoRouter route** that sets `name:` on the route;
/// the observer logs the route’s name, not the URL path. Add `name` on routes
/// in [app_router] to make screens show up in analytics.
///
/// **GA4:** `screen_viewed` with `screen_name` (e.g. `home`, `onboarding`).
final class ScreenViewedEvent extends AnalyticsEvent {
  const ScreenViewedEvent({required this.screenName});

  /// Route `name` from [GoRoute.name] (e.g. `test_session`, `settings`).
  final String screenName;
}

/// **User left a critical screen (or tab)** after a measurable **dwell** period.
/// Use for funnels, drop-off, and “time to complete” (paired with
/// [ScreenViewedEvent] and [ScreenFlowActionEvent] for CTAs / back). See
/// [ScreenDwellRouteObserver] (root stack dwell) plus `ScreenFlow` helpers
/// in `lib/core/analytics/screen_flow_analytics.dart` for modals and shell
/// tab timing.
///
/// [endKind] is stable, query-friendly, e.g.:
/// * `back_pop` — system back or [Navigator] pop
/// * `replaced` — [Navigator] replace (incl. some [GoRouter] `go` transitions)
/// * `shell_tab_change` — bottom bar switched to another main tab
/// * `modal_dismissed` — bottom sheet or dialog closed (CTA in
///   [ScreenFlowActionEvent])
/// * `removed` — [Navigator] removed the route
///
/// **GA4:** `screen_dwell_ended` with `screen_name`, `duration_ms` (0 allowed),
/// `end_kind` (string).
final class ScreenDwellEndedEvent extends AnalyticsEvent {
  const ScreenDwellEndedEvent({
    required this.screenName,
    required this.durationMs,
    required this.endKind,
  });

  final String screenName;
  final int durationMs;
  final String endKind;
}

/// **An explicit user action** on a critical screen (CTA, back, skip) where
/// route-based dwell is not enough.
///
/// **GA4:** `screen_flow_action` with `screen_name`, `action_id` (snake case),
/// `action_kind` (`cta`, `back`, `skip`, `dismiss`, or `other`).
final class ScreenFlowActionEvent extends AnalyticsEvent {
  const ScreenFlowActionEvent({
    required this.screenName,
    required this.actionId,
    this.actionKind = 'cta',
  });

  final String screenName;
  final String actionId;
  final String actionKind;
}

// ── Generic feature funnel (test flows, some catalog features) ───────

sealed class FeatureUsageEvent extends AnalyticsEvent {
  const FeatureUsageEvent({
    required this.featureName,
    required this.subject,
    this.topic,
    this.difficulty,
    required this.source,
  });

  /// Derived product label (e.g. `mcq_practice`, `revision`).
  final String featureName;
  final String subject;
  final String? topic;
  final String? difficulty;
  /// How the user entered the flow (`home`, `share`, etc. — from sessionderive).
  final String source;
}

/// **User opened a feature’s entry screen** (e.g. landed on a catalog surface).
/// Local sink may increment view counters in Drift.
///
/// **GA4:** `feature_viewed` with `feature_name`, `subject`, optional `topic`,
/// optional `difficulty`, `source`.
final class FeatureViewedEvent extends FeatureUsageEvent {
  const FeatureViewedEvent({
    required super.featureName,
    required super.subject,
    super.topic,
    super.difficulty,
    required super.source,
  });
}

/// **User began an interactive flow** (e.g. a timed test has loaded with real
/// questions and the engine is active).
///
/// **GA4:** `feature_started` (same parameters as [FeatureViewedEvent]).
final class FeatureStartedEvent extends FeatureUsageEvent {
  const FeatureStartedEvent({
    required super.featureName,
    required super.subject,
    super.topic,
    super.difficulty,
    required super.source,
  });
}

/// **User finished a session successfully** (submitted/completed, not abandoned).
/// Fired from [TestEngineRepositoryImpl.submitSession] after streak updates.
///
/// **GA4:** `feature_completed` (same parameters as [FeatureViewedEvent]).
final class FeatureCompletedEvent extends FeatureUsageEvent {
  const FeatureCompletedEvent({
    required super.featureName,
    required super.subject,
    super.topic,
    super.difficulty,
    required super.source,
  });
}

// ── Per-question (practice / test) ────────────────────────────────────

/// **User submitted an answer (or the system recorded an attempt)** for one
/// question in a session. High-volume; use for quality/trap/velocity analysis.
///
/// **GA4:** `question_attempted` with `question_id`, `subject`, `topic`,
/// optional `difficulty`, `correct` (0/1), `time_taken_seconds`, `guessed` (0/1),
/// `eliminated_options_count`, optional `trap_type`, optional `confidence_level`,
/// `feature_name`, `source`.
final class QuestionAttemptedEvent extends AnalyticsEvent {
  const QuestionAttemptedEvent({
    required this.questionId,
    required this.subject,
    required this.topic,
    this.difficulty,
    required this.correct,
    required this.timeTakenSeconds,
    required this.guessed,
    required this.eliminatedOptionsCount,
    this.trapType,
    this.confidenceLevel,
    required this.featureName,
    required this.source,
  });

  final String questionId;
  final String subject;
  final String topic;
  final String? difficulty;
  final bool correct;
  final int timeTakenSeconds;
  final bool guessed;
  final int eliminatedOptionsCount;
  final String? trapType;
  final int? confidenceLevel;
  final String featureName;
  final String source;
}

// ── Streaks & revision ────────────────────────────────────────────────

/// **Daily (or study) streak length increased** after a qualifying session
/// complete.
///
/// **GA4:** `streak_continued` with `streak_length` (integer).
final class StreakContinuedEvent extends AnalyticsEvent {
  const StreakContinuedEvent({required this.streakLength});

  final int streakLength;
}

/// **A revision or revision_quick session was completed.**
///
/// **GA4:** `revision_completed` with `questions_count`, `subject`.
final class RevisionCompletedEvent extends AnalyticsEvent {
  const RevisionCompletedEvent({
    required this.questionsCount,
    required this.subject,
  });

  final int questionsCount;
  final String subject;
}

// ── MCQ & battles ─────────────────────────────────────────────────────

/// **User entered the full-screen MCQ test experience** (practice or
/// home-driven test). One event per session start, separate from
/// [FeatureStartedEvent] which is broader.
///
/// **GA4:** `mcq_test_session_started` with `subject`, optional `topic`,
/// optional `analytics_feature_key` (product routing / experiments).
final class McqTestSessionStartedEvent extends AnalyticsEvent {
  const McqTestSessionStartedEvent({
    required this.subject,
    this.topic,
    this.analyticsFeatureKey,
  });

  final String subject;
  final String? topic;
  final String? analyticsFeatureKey;
}

/// **Outcome of sending a battle invite** (FCM / callable result).
/// [kind] values include `push_ok`, `no_token`, `send_failed`, `transport_error`.
///
/// **GA4:** `battle_invite_outcome` with `kind`.
final class BattleInviteOutcomeEvent extends AnalyticsEvent {
  const BattleInviteOutcomeEvent({required this.kind});

  final String kind;
}

/// **Invitee completed join and entered the battle lobby.**
///
/// **GA4:** `battle_invite_accepted` (no parameters).
final class BattleInviteAcceptedEvent extends AnalyticsEvent {
  const BattleInviteAcceptedEvent();
}

// ── Push permission & reminders ───────────────────────────────────────

/// **Snapshot of OS notification permission** from Firebase Messaging
/// (authorized / denied / provisional / not determined / web). Emitted on
/// cold start and resume, debounced to avoid duplicates. Also sets the **user
/// property** `push_alerts` (`on`, `off`, `not_determined`, or `unknown`) in
/// [FirebaseAnalyticsSink] for audience building.
///
/// **GA4:** `push_permission_snapshot` with `status` (string label) and
/// `allows_push` (0/1). User property: `push_alerts`.
final class PushNotificationStatusSnapshotEvent extends AnalyticsEvent {
  const PushNotificationStatusSnapshotEvent({
    required this.status,
    required this.allowsPush,
  });

  final String status;
  final bool allowsPush;
}

/// **Direct outcome** after the OS notification permission dialog closes
/// ([BattleMessagingService.requestPushAuthorizationAndSync]). One event per
/// prompt attempt (not debounced like [PushNotificationStatusSnapshotEvent]).
///
/// **Granted** is also emitted as [PushPermissionGrantedEvent] when
/// `allows_push` is 1, so funnels do not have to filter this event.
///
/// **GA4:** `push_permission_prompt_result` with `status`, `allows_push` (0/1),
/// and `source` (call site, e.g. `post_first_test`). Also updates user
/// property `push_alerts` in [FirebaseAnalyticsSink].
final class PushPermissionPromptResultEvent extends AnalyticsEvent {
  const PushPermissionPromptResultEvent({
    required this.status,
    required this.allowsPush,
    required this.source,
  });

  final String status;
  final bool allowsPush;
  final String source;
}

/// **User granted OS notification permission** after our in-app sheet + system
/// dialog. Fired only when [PushPermissionPromptResultEvent.allowsPush] is true.
///
/// **GA4:** `push_permission_granted` with `source`.
final class PushPermissionGrantedEvent extends AnalyticsEvent {
  const PushPermissionGrantedEvent({required this.source});

  final String source;
}

/// **In-app notification-permission education sheet was shown.** Pair with
/// [DeferredPushEducationModalOutcomeEvent] (close) and
/// [PushPermissionGrantedEvent] (OS allow). Distinct from [ScreenViewedEvent]
/// (`deferred_push_pre_prompt`), which has no `source`.
///
/// **GA4:** `deferred_push_education_shown` with `source` (e.g. `post_first_test`,
/// `daily_war_history`, `daily_ca_screen`, `community_screen`, `ca_card_not_live`).
final class DeferredPushEducationModalShownEvent extends AnalyticsEvent {
  const DeferredPushEducationModalShownEvent({required this.source});

  final String source;
}

/// **Deferred “education” bottom sheet**
/// was closed. Tracks whether the user asked for the system prompt.
///
/// **GA4:** `deferred_push_education_outcome` with:
/// * `source` — screen or CTA, e.g. `daily_war_history`, `daily_ca_screen`,
///   `community_screen`, `ca_card_not_live`, `post_first_test`;
/// * `modal_index` — 1 or 2 (max two education modals);
/// * `tapped_enable` — 1 if the user chose “Turn on notifications”, else 0.
final class DeferredPushEducationModalOutcomeEvent extends AnalyticsEvent {
  const DeferredPushEducationModalOutcomeEvent({
    required this.source,
    required this.modalIndex,
    required this.tappedEnableNotifications,
  });

  final String source;
  final int modalIndex;
  final bool tappedEnableNotifications;
}

/// **Home nudge line was shown** (after two education modals, user still
/// without push). One impression per time the nudge is built and visible for
/// that provider resolution (we dedupe to once per build cycle).
///
/// **GA4:** `deferred_push_home_nudge_shown` (no parameters).
final class DeferredPushHomeNudgeShownEvent extends AnalyticsEvent {
  const DeferredPushHomeNudgeShownEvent();
}

/// **User tapped “Turn on notifications”** on the home nudge (may open
/// system settings or request permission).
///
/// **GA4:** `deferred_push_home_nudge_tap_enable` (no parameters).
final class DeferredPushHomeNudgeTapEnableEvent extends AnalyticsEvent {
  const DeferredPushHomeNudgeTapEnableEvent();
}

/// **User dismissed the home nudge** with the close control (prefs updated
/// so it does not reappear for that nudge class).
///
/// **GA4:** `deferred_push_home_nudge_dismissed` (no parameters).
final class DeferredPushHomeNudgeDismissedEvent extends AnalyticsEvent {
  const DeferredPushHomeNudgeDismissedEvent();
}

// ── First-run onboarding (thesis → depth → games list) ──────────

/// **Time the user spent on one horizontal step** of the first-run flow before
/// swiping to the next, or the last step before “Let’s go.” [step] is
/// `thesis`, `depth`, or `games`.
///
/// **GA4:** `onboarding_step_duration` with `step`, `duration_ms` (int).
final class OnboardingStepDurationEvent extends AnalyticsEvent {
  const OnboardingStepDurationEvent({
    required this.step,
    required this.durationMs,
  });

  final String step;
  final int durationMs;
}

/// **The three-page onboarding flow screen opened** (funnel start).
///
/// **GA4:** `onboarding_flow_opened` (no parameters).
final class OnboardingFlowOpenedEvent extends AnalyticsEvent {
  const OnboardingFlowOpenedEvent();
}

/// **User finished onboarding** (last-page CTA or Skip); [totalDurationMs] is
/// time since [OnboardingFlowOpenedEvent] for the same visit.
///
/// **GA4:** `onboarding_flow_completed` with `total_duration_ms` (int).
final class OnboardingFlowCompletedEvent extends AnalyticsEvent {
  const OnboardingFlowCompletedEvent({required this.totalDurationMs});

  final int totalDurationMs;
}

/// **User left onboarding without finishing** (navigated away or the widget
/// was disposed) without a successful [OnboardingFlowCompletedEvent]. Funnel
/// drop-out signal.
///
/// **GA4:** `onboarding_exited_incomplete` with:
/// * `highest_step` — furthest step id reached (`thesis` / `depth` / `games`);
/// * `last_step` — page index at exit mapped the same way;
/// * `elapsed_ms` — time from flow open;
/// * `reached_last_step` — 1 if the user ever reached the final horizontal page.
final class OnboardingExitedIncompleteEvent extends AnalyticsEvent {
  const OnboardingExitedIncompleteEvent({
    required this.highestStep,
    required this.lastStep,
    required this.elapsedMs,
    required this.reachedLastStep,
  });

  final String highestStep;
  final String lastStep;
  final int elapsedMs;
  final bool reachedLastStep;
}

// ── Session completion & drop-off ────────────────────────────────────

/// **First time any test session in local storage reached `completed`**
/// (activation for D1). Includes practice sessions completed through
/// [TestEngineRepositoryImpl.submitSession] (and any other path that writes
/// the same `sessions` row to completed, if any).
///
/// **GA4:** `first_session_completed` (no parameters; once per app install
/// for that user on device).
final class FirstSessionCompletedEvent extends AnalyticsEvent {
  const FirstSessionCompletedEvent();
}

/// **A session was marked abandoned** (user left without finishing/submit
/// through the normal “mark abandoned” use case, e.g. from test or battle
/// exit). Use with [FeatureStartedEvent] to compute abandon rate by flow.
///
/// **GA4:** `test_session_abandoned` with `feature_name`, `subject`, optional
/// `topic`, `source` (same meaning as in feature usage).
final class TestSessionAbandonedEvent extends AnalyticsEvent {
  const TestSessionAbandonedEvent({
    required this.featureName,
    required this.subject,
    this.topic,
    required this.source,
  });

  final String featureName;
  final String subject;
  final String? topic;
  final String source;
}

// ── Activation (per-device, first time) — see [activation_milestones] ─

/// **User reached a one-time product step**; [milestoneId] matches
/// [ActivationMilestones] in `activation_milestones.dart`.
///
/// **GA4:** `activation_milestone` with `milestone_id` (string).
final class ActivationMilestoneEvent extends AnalyticsEvent {
  const ActivationMilestoneEvent({required this.milestoneId});

  final String milestoneId;
}

// ── Confidence marking ────────────────────────────────────────────────

/// **User picked a confidence tier** (Sure / Educated guess / Pure guess).
///
/// Emitted once per tier selection (not when clearing). Use with
/// [ConfidenceTrackingToggledEvent] to measure adoption vs opt-out.
///
/// **GA4:** `confidence_marked` with `confidence_level` (1–3), `session_mode`,
/// `marking_source` (`pre_reveal_prompt` | `option_strip`), `feature_name`,
/// `source`.
final class ConfidenceMarkedEvent extends AnalyticsEvent {
  const ConfidenceMarkedEvent({
    required this.confidenceLevel,
    required this.sessionMode,
    required this.markingSource,
    required this.featureName,
    required this.source,
  });

  final int confidenceLevel;
  final String sessionMode;
  final String markingSource;
  final String featureName;
  final String source;
}

/// **User enabled or disabled confidence tracking** in Settings.
///
/// **GA4:** `confidence_tracking_toggled` with `enabled` (0/1).
final class ConfidenceTrackingToggledEvent extends AnalyticsEvent {
  const ConfidenceTrackingToggledEvent({required this.enabled});

  final bool enabled;
}

// ── UPSC Wars “USP” — result snapshot & coach —──────────────────────

/// **Confidence and Danger Zone aggregates** at session submit (one row per
/// completed session, practice flows).
///
/// **GA4:** `usp_session_result` — see [FirebaseAnalyticsSink] for param keys.
final class UspSessionResultSnapshotEvent extends AnalyticsEvent {
  const UspSessionResultSnapshotEvent({
    required this.featureKey,
    required this.subject,
    required this.questionCount,
    required this.correct,
    required this.wrong,
    required this.accuracyHundredths,
    required this.dangerZoneWrongCount,
    required this.sureTotal,
    required this.sureCorrect,
    required this.intelligentTotal,
    required this.intelligentCorrect,
    required this.pureTotal,
    required this.pureCorrect,
  });

  final String featureKey;
  final String subject;
  final int questionCount;
  final int correct;
  final int wrong;
  final int accuracyHundredths;
  final int dangerZoneWrongCount;
  final int sureTotal;
  final int sureCorrect;
  final int intelligentTotal;
  final int intelligentCorrect;
  final int pureTotal;
  final int pureCorrect;
}

/// **User tapped a post-results coach CTA** (Danger Zone, next step, etc.).
///
/// **GA4:** `usp_coach_cta` with `action` (snake_case, see app integration).
final class UspSessionCoachCtaTappedEvent extends AnalyticsEvent {
  const UspSessionCoachCtaTappedEvent({required this.action});

  final String action;
}

/// **App opened from a system notification** (data message / local notif tap).
///
/// **GA4:** `app_notification_open` with `channel` (`fcm` | `local`),
/// `kind` (routing hint: `battle_join` | `open_challenge` | `long_html` | `unknown`).
final class AppNotificationOpenEvent extends AnalyticsEvent {
  const AppNotificationOpenEvent({required this.channel, required this.kind});

  final String channel;
  final String kind;
}

/// **User signed in to a real account** (not anonymous). Fired on each
/// anonymous → account transition so retention can be segmented by identity.
///
/// **GA4:** `account_signed_in` with optional `method` (provider id hint).
final class AccountSignedInEvent extends AnalyticsEvent {
  const AccountSignedInEvent({this.method});

  final String? method;
}

// ── Insights & recommendations ─────────────────────────────────────────────

/// **First time the user saw any Insights surface** (per device).
///
/// This is intentionally a one-time event (guarded by [PrefsService]) to power
/// activation funnels for analytics.
///
/// **GA4:** `first_insight_seen` (no parameters).
final class FirstInsightSeenEvent extends AnalyticsEvent {
  const FirstInsightSeenEvent();
}

/// **User opened the Insights / Weak Areas dashboard.**
///
/// **GA4:** `insights_dashboard_opened` (no parameters).
final class InsightsDashboardOpenedEvent extends AnalyticsEvent {
  const InsightsDashboardOpenedEvent();
}

/// **User opened Trap Awareness / Trap Patterns.**
///
/// **GA4:** `trap_awareness_opened` (no parameters).
final class TrapAwarenessOpenedEvent extends AnalyticsEvent {
  const TrapAwarenessOpenedEvent();
}

/// **User clicked a revision recommendation** CTA (nudge card, quick practice).
///
/// **GA4:** `revision_recommendation_clicked` with `source` (string).
final class RevisionRecommendationClickedEvent extends AnalyticsEvent {
  const RevisionRecommendationClickedEvent({required this.source});

  final String source;
}

/// **User clicked a “risk” card** (e.g. subject row/risk badge surface).
///
/// **GA4:** `risk_card_clicked` with `subject` and `risk_tier`.
final class RiskCardClickedEvent extends AnalyticsEvent {
  const RiskCardClickedEvent({
    required this.subject,
    required this.riskTier,
  });

  final String subject;
  final String riskTier;
}

// ── Home activation ─────────────────────────────────────────────────────────

/// **Get Started card shown** on home for pre-activation users.
///
/// **GA4:** `get_started_card_shown` (no parameters).
final class GetStartedCardShownEvent extends AnalyticsEvent {
  const GetStartedCardShownEvent();
}

/// **User tapped Get Started** on home.
///
/// **GA4:** `get_started_card_tapped` with optional `subject`, `source`.
final class GetStartedCardTappedEvent extends AnalyticsEvent {
  const GetStartedCardTappedEvent({this.subject, this.source});

  final String? subject;

  /// e.g. `onboarding`, `home_card`, `subject_sheet`.
  final String? source;
}

/// **User snoozed the Get Started home card** until tomorrow.
///
/// **GA4:** `get_started_card_snoozed` (no parameters).
final class GetStartedCardSnoozedEvent extends AnalyticsEvent {
  const GetStartedCardSnoozedEvent();
}

/// **Activation journey checklist shown** on home.
///
/// **GA4:** `activation_journey_shown` with `todo1_done`, `scored_attempts`,
/// `todo2_unlocked` (0/1).
final class ActivationJourneyShownEvent extends AnalyticsEvent {
  const ActivationJourneyShownEvent({
    required this.todo1Done,
    required this.scoredAttempts,
    required this.todo2Unlocked,
  });

  final bool todo1Done;
  final int scoredAttempts;
  final bool todo2Unlocked;
}

/// **User tapped a step** on the activation journey checklist.
///
/// **GA4:** `activation_journey_todo_tapped` with `todo_index` (1–3).
final class ActivationJourneyTodoTappedEvent extends AnalyticsEvent {
  const ActivationJourneyTodoTappedEvent({required this.todoIndex});

  final int todoIndex;
}

/// **User snoozed the START HERE checklist** until tomorrow.
///
/// **GA4:** `activation_journey_snoozed` (no parameters).
final class ActivationJourneySnoozedEvent extends AnalyticsEvent {
  const ActivationJourneySnoozedEvent();
}

// ── Revision Games (mini-games hub + Memory Pairs) ───────────────────────────

/// **User opened a revision-game surface** (hub or a specific game screen).
///
/// **GA4:** `game_screen_opened` with `game_name`
/// (e.g. `games_hub`, `timeline_sorter`, `odd_one_out`, `fact_or_bluff`,
/// `connect_the_dots`, `duel`, `memory_pairs`).
final class GameScreenOpenedEvent extends AnalyticsEvent {
  const GameScreenOpenedEvent({required this.gameName});

  final String gameName;
}

/// **User started a playable game session** (how-to dismissed / skipped and
/// content ready, or Play again).
///
/// **GA4:** `game_started` with `game_name`, optional `total_rounds`.
final class GameStartedEvent extends AnalyticsEvent {
  const GameStartedEvent({
    required this.gameName,
    this.totalRounds,
  });

  final String gameName;
  final int? totalRounds;
}

/// **User finished a full game session** (all rounds/questions done — the
/// session “round of play”, not a single question).
///
/// Use with [GameStartedEvent] for start→finish conversion by `game_name`.
///
/// **GA4:** `game_round_finished` with `game_name`, `correct_count`,
/// `total_rounds`.
final class GameRoundFinishedEvent extends AnalyticsEvent {
  const GameRoundFinishedEvent({
    required this.gameName,
    required this.correctCount,
    required this.totalRounds,
  });

  final String gameName;
  final int correctCount;
  final int totalRounds;
}

// ── Memory Pairs (Revision Games) ────────────────────────────────────────────

/// **First time the user opened Memory Pairs / Revision Games** (per device).
///
/// **GA4:** `memory_pairs_game_discovered` (no parameters).
final class MemoryPairsGameDiscoveredEvent extends AnalyticsEvent {
  const MemoryPairsGameDiscoveredEvent();
}

/// **First time the user started a Memory Pairs match game** (per device).
///
/// **GA4:** `memory_pairs_game_played` with `set_id`, `difficulty`.
final class MemoryPairsGamePlayedEvent extends AnalyticsEvent {
  const MemoryPairsGamePlayedEvent({
    required this.setId,
    required this.difficulty,
  });

  final String setId;
  final String difficulty;
}

/// **User started the daily practice drill** from home.
///
/// **GA4:** `daily_drill_started` with `subject`, `source`, `completed_today`.
final class DailyDrillStartedEvent extends AnalyticsEvent {
  const DailyDrillStartedEvent({
    required this.subject,
    required this.source,
    required this.completedToday,
  });

  final String subject;
  final String source;
  final bool completedToday;
}

/// **User changed daily practice subject** via the gear sheet.
///
/// **GA4:** `daily_drill_subject_changed` with `subject`.
final class DailyDrillSubjectChangedEvent extends AnalyticsEvent {
  const DailyDrillSubjectChangedEvent({required this.subject});

  final String subject;
}

/// **Session summary hero insight case** rendered after a test.
///
/// **GA4:** `session_insight_case_shown` with `case`, `sure_wrong`, `edu_wrong`.
final class SessionInsightCaseShownEvent extends AnalyticsEvent {
  const SessionInsightCaseShownEvent({
    required this.caseName,
    required this.sureWrong,
    required this.eduWrong,
  });

  final String caseName;
  final int sureWrong;
  final int eduWrong;
}

// ── Daily War ────────────────────────────────────────────────────────────────

/// **Daily War home card was shown** (feature enabled + card mounted).
///
/// Pair with [AppOpenedEvent] / GA4 Active users for “app users who saw War”,
/// and with [DailyWarAttemptedEvent] for saw → attempt conversion.
///
/// **GA4:** `daily_war_home_shown` with `date_id`, `phase`, `is_grand` (0/1).
final class DailyWarHomeShownEvent extends AnalyticsEvent {
  const DailyWarHomeShownEvent({
    required this.dateId,
    required this.phase,
    required this.isGrand,
  });

  final String dateId;
  final String phase;
  final bool isGrand;
}

/// **User started a Daily War paper** (live lobby join or unranked attempt).
///
/// Use unique users on this event for “how many are attempting Daily War”.
/// App-wide users remain [AppOpenedEvent] / GA4 Active users.
///
/// **GA4:** `daily_war_attempted` with `date_id`, `mode` (`live`|`unranked`),
/// `is_grand` (0/1). Also sets user property `daily_war_player` = `yes`.
final class DailyWarAttemptedEvent extends AnalyticsEvent {
  const DailyWarAttemptedEvent({
    required this.dateId,
    required this.mode,
    required this.isGrand,
  });

  final String dateId;

  /// `live` or `unranked`.
  final String mode;
  final bool isGrand;
}

/// **Daily War answers were accepted by Cloud Functions** after a paper.
///
/// Pair with [DailyWarAttemptedEvent] for start → submit conversion.
///
/// **GA4:** `daily_war_submitted` with `date_id`, `mode` (`live`|`unranked`),
/// `is_grand` (0/1), `score_hundredths` (score × 100, int).
final class DailyWarSubmittedEvent extends AnalyticsEvent {
  const DailyWarSubmittedEvent({
    required this.dateId,
    required this.mode,
    required this.isGrand,
    required this.score,
  });

  final String dateId;
  final String mode;
  final bool isGrand;
  final double score;
}

// ── CA Shots (FOMO Pulse) ────────────────────────────────────────────────────

/// **User tapped a CA Shot push notification.**
///
/// Funnel step 1. Pair unique users with [CaShotSummaryViewedEvent],
/// [CaShotMcqOpenedEvent], and [CaShotAttemptedEvent].
///
/// **GA4:** `ca_shot_notif_opened` with `pulse_id`, `channel` (`fcm`|`local`).
final class CaShotNotifOpenedEvent extends AnalyticsEvent {
  const CaShotNotifOpenedEvent({
    required this.pulseId,
    required this.channel,
  });

  final String pulseId;
  final String channel;
}

/// **CA Shot news summary was shown** (News tab on the detail screen).
///
/// Funnel step 2 — they opened the shot and saw the briefing.
/// [source] is `push` | `history` | `share` | `in_app`.
///
/// **GA4:** `ca_shot_summary_viewed` with `pulse_id`, `source`.
final class CaShotSummaryViewedEvent extends AnalyticsEvent {
  const CaShotSummaryViewedEvent({
    required this.pulseId,
    required this.source,
  });

  final String pulseId;
  final String source;
}

/// **User switched to the MCQ tab** (or opened the standalone MCQ screen).
///
/// Funnel step 3. Does not mean they answered.
///
/// **GA4:** `ca_shot_mcq_opened` with `pulse_id`, `source`,
/// `already_attempted` (0/1).
final class CaShotMcqOpenedEvent extends AnalyticsEvent {
  const CaShotMcqOpenedEvent({
    required this.pulseId,
    required this.source,
    required this.alreadyAttempted,
  });

  final String pulseId;
  final String source;
  final bool alreadyAttempted;
}

/// **User submitted an answer on a CA Shot MCQ** (first attempt this visit).
///
/// Funnel step 4. Use unique users vs [CaShotSummaryViewedEvent] for
/// open → attempt conversion; vs [CaShotNotifOpenedEvent] for push → attempt.
///
/// **GA4:** `ca_shot_attempted` with `pulse_id`, `source`, `correct` (0/1).
final class CaShotAttemptedEvent extends AnalyticsEvent {
  const CaShotAttemptedEvent({
    required this.pulseId,
    required this.source,
    required this.correct,
  });

  final String pulseId;
  final String source;
  final bool correct;
}
