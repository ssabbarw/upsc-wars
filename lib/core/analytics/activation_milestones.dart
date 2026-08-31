import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/prefs_provider.dart';
import 'analytics.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// One-time **product activation** checkpoints (D1 / “wow” funnel). Each [id] is
/// only logged to GA4 the first time it is recorded on this device.
///
/// Pair with [ActivationMilestoneEvent] in [FirebaseAnalyticsSink]; ids are
/// contract strings — use [ActivationMilestones] constants in call sites.
abstract final class ActivationMilestones {
  const ActivationMilestones._();

  static const firstProcessLaunch = 'first_process_launch';
  static const onboardingFlowCompleted = 'onboarding_flow_completed';

  /// First home visit after onboarding when the Get Started demo sheet is shown.
  static const onboardingComplete = 'onboarding_complete';
  static const firstMcqTestEntered = 'first_mcq_test_entered';
  static const firstDangerZoneReview = 'first_danger_zone_review_opened';
  static const firstQotdAttempt = 'first_qotd_mcq_attempt';
  static const firstQotdPosted = 'first_qotd_posted_to_community';
  static const firstBattleInvitePushOk = 'first_battle_invite_sent_push_ok';
  static const firstBattleLobbyJoined = 'first_battle_lobby_joined';
  static const firstBookmark = 'first_question_bookmark';
  static const firstRevisionTest = 'first_revision_test_started';
  static const firstScorecardShare = 'first_session_scorecard_link_shared';
  static const firstAccountSignIn = 'first_account_signed_in';
  static const getStartedDiagnosticCompleted = 'get_started_diagnostic_completed';

  /// First test finished on device (demo diagnostic or any persisted session).
  static const firstTestDone = 'first_test_done';

  /// First finished session that is not the Get Started demo diagnostic.
  static const firstNonDemoTestDone = 'first_non_demo_test_done';

  /// Studied on a 2nd distinct calendar day — the activation north-star.
  static const activatedSecondDay = 'activated_second_active_day';

  /// Studied on a 3rd distinct calendar day — early habit / retention.
  static const habituatedThreeDays = 'habituated_three_active_days';

  /// User left their first test before submitting (demo or any session).
  static const firstTestQuitInMid = 'first_test_quit_in_mid';

  /// First time an explanation body was on screen (demo or later).
  static const firstExplanationViewed = 'first_explanation_viewed';

  /// First time the Statements deep-dive tab was visible.
  static const firstStatementAnalysisViewed = 'first_statement_analysis_viewed';

  /// First time the Elimination deep-dive tab was visible.
  static const firstEliminationViewed = 'first_elimination_viewed';

  /// First time the Trap deep-dive tab was visible.
  static const firstTrapViewed = 'first_trap_viewed';

  /// Opened mistake review after the Get Started demo.
  static const firstDemoMistakesReviewed = 'first_demo_mistakes_reviewed';

  /// Opened review-all / full explanations after the Get Started demo.
  static const firstDemoExplanationsReviewed =
      'first_demo_explanations_reviewed';

  /// First non-demo product surface after completing the demo (subject, tab,
  /// today hub, another test).
  static const firstPostDemoExplore = 'first_post_demo_explore';

  /// First time the app was opened or resumed after the demo was completed.
  static const firstReturnAfterDemo = 'first_return_after_demo';
}

/// Sets [PrefsService.homeActivationComplete] when Sure/Educated is logged.
void markHomeActivationComplete(PrefsService prefs) {
  if (prefs.homeActivationComplete) return;
  prefs.homeActivationComplete = true;
}

/// GA4 `activation_milestone` with `milestone_id` = [ActivationMilestones.firstTestDone].
Future<void> logFirstTestDoneForServices(
  AnalyticsService analytics,
  PrefsService prefs,
) async {
  if (prefs.hasActivationMilestone(ActivationMilestones.firstTestDone)) return;
  prefs.pushPermissionPromptPendingAfterFirstTest = true;
  await logActivationMilestoneForServices(
    analytics,
    prefs,
    id: ActivationMilestones.firstTestDone,
  );
}

/// GA4 `activation_milestone` with `milestone_id` = [ActivationMilestones.firstTestQuitInMid].
/// No-op after [ActivationMilestones.firstTestDone] is already logged.
Future<void> logFirstTestQuitInMidForServices(
  AnalyticsService analytics,
  PrefsService prefs,
) async {
  if (prefs.hasActivationMilestone(ActivationMilestones.firstTestDone)) return;
  await logActivationMilestoneForServices(
    analytics,
    prefs,
    id: ActivationMilestones.firstTestQuitInMid,
  );
}

/// Logs [ActivationMilestoneEvent] at most once per [id] (see [PrefsService]).
Future<void> logActivationMilestoneOnce(
  WidgetRef ref,
  String id,
) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (prefs.hasActivationMilestone(id)) return;
  prefs.addActivationMilestone(id);
  ref.invalidate(prefsServiceProvider);
  await Analytics.track(ref, ActivationMilestoneEvent(milestoneId: id));
}

/// Same as [logActivationMilestoneOnce] for code paths that only have
/// [AnalyticsService] + [PrefsService] (repositories).
Future<void> logActivationMilestoneForServices(
  AnalyticsService analytics,
  PrefsService prefs, {
  required String id,
}) async {
  if (prefs.hasActivationMilestone(id)) return;
  prefs.addActivationMilestone(id);
  await analytics.track(ActivationMilestoneEvent(milestoneId: id));
}

const _explanationSectionMilestones = <String, String>{
  'explanation': ActivationMilestones.firstExplanationViewed,
  'statements': ActivationMilestones.firstStatementAnalysisViewed,
  'elimination': ActivationMilestones.firstEliminationViewed,
  'trap': ActivationMilestones.firstTrapViewed,
};

const _repeatableExplanationSources = {
  'demo_test',
  'demo_review',
  'in_test',
  'session_review',
  'mistake_review',
};

/// Explanation / Statements / Elimination / Trap became visible.
///
/// Always records the matching one-time [ActivationMilestones] id. Also emits
/// [ExplanationSectionViewedEvent] for onboarding-relevant [source] values.
Future<void> logExplanationSectionViewed(
  WidgetRef ref, {
  required String section,
  String source = 'other',
}) async {
  if (_repeatableExplanationSources.contains(source)) {
    await Analytics.track(
      ref,
      ExplanationSectionViewedEvent(section: section, source: source),
    );
  }
  final id = _explanationSectionMilestones[section];
  if (id != null) {
    await logActivationMilestoneOnce(ref, id);
  }
}

/// Post-demo mistake review or review-all. No-op until the demo is submitted.
Future<void> logDemoReviewOpened(
  WidgetRef ref, {
  required String kind,
}) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (!prefs.getStartedDiagnosticAttempted) return;
  await Analytics.track(ref, DemoReviewOpenedEvent(kind: kind));
  await logActivationMilestoneOnce(
    ref,
    kind == 'mistakes'
        ? ActivationMilestones.firstDemoMistakesReviewed
        : ActivationMilestones.firstDemoExplanationsReviewed,
  );
}

/// Home / another test / a shell tab after the demo. No-op until submitted.
Future<void> maybeLogPostDemoExplore(
  WidgetRef ref, {
  required String surface,
}) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (!prefs.getStartedDiagnosticAttempted) return;
  await Analytics.track(ref, PostDemoExploreEvent(surface: surface));
  await logActivationMilestoneOnce(
    ref,
    ActivationMilestones.firstPostDemoExplore,
  );
}

/// App opened or resumed after the demo was completed (came back).
Future<void> maybeLogReturnAfterDemo(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (!prefs.getStartedDiagnosticAttempted) return;
  await logActivationMilestoneOnce(
    ref,
    ActivationMilestones.firstReturnAfterDemo,
  );
}

