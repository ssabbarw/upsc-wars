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
