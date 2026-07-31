import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_events.dart';
import 'analytics_sink.dart';

/// Sends [AnalyticsEvent] instances to **Google Analytics 4 (Firebase)** via
/// [FirebaseAnalytics.logEvent]. The **English description** of each product
/// event lives on the corresponding class in [analytics_events.dart]. This
/// file only maps **Dart type → GA4 event `name` and parameter keys**.
///
/// **Event name quick reference (GA4 `name` = left, parameters = right):**
/// * `app_opened` — (none)
/// * `session_started` / `session_ended` — (none) — custom app foreground/background
/// * `screen_viewed` — `screen_name`
/// * `screen_dwell_ended` — `screen_name`, `duration_ms`, `end_kind` (see
///   [ScreenDwellRouteObserver], [ScreenFlow] for shell + modals)
/// * `screen_flow_action` — `screen_name`, `action_id`, `action_kind`
/// * `feature_viewed` / `feature_started` / `feature_completed` — `feature_name`, `subject`, `topic?`, `difficulty?`, `source`
/// * `question_attempted` — per-question fields (see [QuestionAttemptedEvent])
/// * `paywall_viewed` / `subscription_started` / `subscription_completed` — `source_feature`, `plan_type?`
/// * `streak_continued` — `streak_length`
/// * `revision_completed` — `questions_count`, `subject`
/// * `mcq_test_session_started` — `subject`, `topic?`, `analytics_feature_key?`
/// * `battle_invite_outcome` — `kind`
/// * `battle_invite_accepted` — (none)
/// * `push_permission_snapshot` — `status`, `allows_push` (0/1); also sets user property `push_alerts`
/// * `push_permission_prompt_result` — `status`, `allows_push` (0/1), `source`; also sets `push_alerts`
/// * `onboarding_step_duration` — `step`, `duration_ms`
/// * `onboarding_reveal_trial_swiped` — (none)
/// * `onboarding_flow_opened` / `onboarding_flow_completed` — `total_duration_ms` on completed only
/// * `onboarding_exited_incomplete` — `highest_step`, `last_step`, `elapsed_ms`, `reached_last_step` (0/1)
/// * `deferred_push_education_outcome` — `source`, `modal_index`, `tapped_enable` (0/1)
/// * `deferred_push_home_nudge_shown` / `deferred_push_home_nudge_tap_enable` /
///   `deferred_push_home_nudge_dismissed` — (none) for nudge events
/// * `first_session_completed` — (none)
/// * `test_session_abandoned` — `feature_name`, `subject`, `topic?`, `source`
/// * `activation_milestone` — `milestone_id` (one-time activation funnel, see
///   [ActivationMilestones] in [activation_milestones.dart])
/// * `confidence_marked` — `confidence_level` (1–3), `session_mode`,
///   `marking_source` (`pre_reveal_prompt` | `option_strip`), `feature_name`, `source`
/// * `confidence_tracking_toggled` — `enabled` (0/1)
/// * `usp_session_result` — session snapshot: `feature_key`, `subject`,
///   `question_count`, `correct`, `wrong`, `accuracy_hundredths`, `danger_zone_wrong`,
///   and confidence bucket totals (see [UspSessionResultSnapshotEvent])
/// * `usp_coach_cta` — `action` (result coach / Danger Zone CTA labels)
/// * `app_notification_open` — `channel` (`fcm` / `local`), `kind` (e.g. battle)
/// * `game_screen_opened` — `game_name`
/// * `game_started` — `game_name`, `total_rounds?`
/// * `game_round_finished` — `game_name`, `correct_count`, `total_rounds`
///
/// All events also send `user_id` when the user is signed in to Firebase Auth.
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink({
    FirebaseAnalytics? analytics,
    FirebaseAuth? auth,
  })  : _analytics = analytics ?? FirebaseAnalytics.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAnalytics _analytics;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;

  @override
  Future<void> send(AnalyticsEvent event) async {
    switch (event) {
      case AppOpenedEvent():
        await _log('app_opened', const {});
      case SessionStartedEvent():
        await _log('session_started', const {});
      case SessionEndedEvent():
        await _log('session_ended', const {});
      case ScreenViewedEvent(:final screenName):
        await _log('screen_viewed', {'screen_name': screenName});
      case ScreenDwellEndedEvent(
          :final screenName,
          :final durationMs,
          :final endKind,
        ):
        await _log('screen_dwell_ended', {
          'screen_name': screenName,
          'duration_ms': durationMs,
          'end_kind': endKind,
        });
      case ScreenFlowActionEvent(
          :final screenName,
          :final actionId,
          :final actionKind,
        ):
        await _log('screen_flow_action', {
          'screen_name': screenName,
          'action_id': actionId,
          'action_kind': actionKind,
        });
      case FeatureViewedEvent(
          :final featureName,
          :final subject,
          :final topic,
          :final difficulty,
          :final source,
        ):
        await _log('feature_viewed', {
          'feature_name': featureName,
          'subject': subject,
          if (topic case final t?) 'topic': t,
          if (difficulty case final d?) 'difficulty': d,
          'source': source,
        });
      case FeatureStartedEvent(
          :final featureName,
          :final subject,
          :final topic,
          :final difficulty,
          :final source,
        ):
        await _log('feature_started', {
          'feature_name': featureName,
          'subject': subject,
          if (topic case final t?) 'topic': t,
          if (difficulty case final d?) 'difficulty': d,
          'source': source,
        });
      case FeatureCompletedEvent(
          :final featureName,
          :final subject,
          :final topic,
          :final difficulty,
          :final source,
        ):
        await _log('feature_completed', {
          'feature_name': featureName,
          'subject': subject,
          if (topic case final t?) 'topic': t,
          if (difficulty case final d?) 'difficulty': d,
          'source': source,
        });
      case QuestionAttemptedEvent(
          :final questionId,
          :final subject,
          :final topic,
          :final difficulty,
          :final correct,
          :final timeTakenSeconds,
          :final guessed,
          :final eliminatedOptionsCount,
          :final trapType,
          :final confidenceLevel,
          :final featureName,
          :final source,
        ):
        await _log('question_attempted', {
          'question_id': questionId,
          'subject': subject,
          'topic': topic,
          if (difficulty case final d?) 'difficulty': d,
          'correct': correct ? 1 : 0,
          'time_taken_seconds': timeTakenSeconds,
          'guessed': guessed ? 1 : 0,
          'eliminated_options_count': eliminatedOptionsCount,
          if (trapType case final tr?) 'trap_type': tr,
          if (confidenceLevel case final c?) 'confidence_level': c,
          'feature_name': featureName,
          'source': source,
        });
      case PaywallViewedEvent(:final sourceFeature, :final planType):
        await _log('paywall_viewed', {
          'source_feature': sourceFeature,
          if (planType case final p?) 'plan_type': p,
        });
      case SubscriptionStartedEvent(:final sourceFeature, :final planType):
        await _log('subscription_started', {
          'source_feature': sourceFeature,
          if (planType case final p?) 'plan_type': p,
        });
      case SubscriptionCompletedEvent(:final sourceFeature, :final planType):
        await _log('subscription_completed', {
          'source_feature': sourceFeature,
          if (planType case final p?) 'plan_type': p,
        });
      case StreakContinuedEvent(:final streakLength):
        await _log('streak_continued', {
          'streak_length': streakLength,
        });
      case RevisionCompletedEvent(:final questionsCount, :final subject):
        await _log('revision_completed', {
          'questions_count': questionsCount,
          'subject': subject,
        });
      case McqTestSessionStartedEvent(
          :final subject,
          :final topic,
          :final analyticsFeatureKey,
        ):
        await _log('mcq_test_session_started', {
          'subject': subject,
          if (topic case final t?) 'topic': t,
          if (analyticsFeatureKey case final k?) 'analytics_feature_key': k,
        });
      case BattleInviteOutcomeEvent(:final kind):
        await _log('battle_invite_outcome', {'kind': kind});
      case BattleInviteAcceptedEvent():
        await _log('battle_invite_accepted', const {});
      case PushNotificationStatusSnapshotEvent(
          :final status,
          :final allowsPush,
        ):
        await _setPushAlertsUserProperty(status);
        await _log('push_permission_snapshot', {
          'status': status,
          'allows_push': allowsPush ? 1 : 0,
        });
      case PushPermissionPromptResultEvent(
          :final status,
          :final allowsPush,
          :final source,
        ):
        await _setPushAlertsUserProperty(status);
        await _log('push_permission_prompt_result', {
          'status': status,
          'allows_push': allowsPush ? 1 : 0,
          'source': source,
        });
      case OnboardingStepDurationEvent(
          :final step,
          :final durationMs,
        ):
        await _log('onboarding_step_duration', {
          'step': step,
          'duration_ms': durationMs,
        });
      case OnboardingRevealTrialSwipedEvent():
        await _log('onboarding_reveal_trial_swiped', const {});
      case OnboardingFlowOpenedEvent():
        await _log('onboarding_flow_opened', const {});
      case OnboardingFlowCompletedEvent(:final totalDurationMs):
        await _log('onboarding_flow_completed', {
          'total_duration_ms': totalDurationMs,
        });
      case OnboardingExitedIncompleteEvent(
          :final highestStep,
          :final lastStep,
          :final elapsedMs,
          :final reachedLastStep,
        ):
        await _log('onboarding_exited_incomplete', {
          'highest_step': highestStep,
          'last_step': lastStep,
          'elapsed_ms': elapsedMs,
          'reached_last_step': reachedLastStep ? 1 : 0,
        });
      case DeferredPushEducationModalOutcomeEvent(
          :final source,
          :final modalIndex,
          :final tappedEnableNotifications,
        ):
        await _log('deferred_push_education_outcome', {
          'source': source,
          'modal_index': modalIndex,
          'tapped_enable': tappedEnableNotifications ? 1 : 0,
        });
      case DeferredPushHomeNudgeShownEvent():
        await _log('deferred_push_home_nudge_shown', const {});
      case DeferredPushHomeNudgeTapEnableEvent():
        await _log('deferred_push_home_nudge_tap_enable', const {});
      case DeferredPushHomeNudgeDismissedEvent():
        await _log('deferred_push_home_nudge_dismissed', const {});
      case FirstSessionCompletedEvent():
        await _log('first_session_completed', const {});
      case TestSessionAbandonedEvent(
          :final featureName,
          :final subject,
          :final topic,
          :final source,
        ):
        await _log('test_session_abandoned', {
          'feature_name': featureName,
          'subject': subject,
          if (topic case final t?) 'topic': t,
          'source': source,
        });
      case ActivationMilestoneEvent(:final milestoneId):
        await _log('activation_milestone', {
          'milestone_id': milestoneId,
        });
      case UspSessionResultSnapshotEvent(
          :final featureKey,
          :final subject,
          :final questionCount,
          :final correct,
          :final wrong,
          :final accuracyHundredths,
          :final dangerZoneWrongCount,
          :final sureTotal,
          :final sureCorrect,
          :final intelligentTotal,
          :final intelligentCorrect,
          :final pureTotal,
          :final pureCorrect,
        ):
        await _log('usp_session_result', {
          'feature_key': featureKey,
          'subject': subject,
          'question_count': questionCount,
          'correct': correct,
          'wrong': wrong,
          'accuracy_hundredths': accuracyHundredths,
          'danger_zone_wrong': dangerZoneWrongCount,
          'confidence_sure_total': sureTotal,
          'confidence_sure_correct': sureCorrect,
          'confidence_intelligent_total': intelligentTotal,
          'confidence_intelligent_correct': intelligentCorrect,
          'confidence_pure_total': pureTotal,
          'confidence_pure_correct': pureCorrect,
        });
      case ConfidenceMarkedEvent(
          :final confidenceLevel,
          :final sessionMode,
          :final markingSource,
          :final featureName,
          :final source,
        ):
        await _log('confidence_marked', {
          'confidence_level': confidenceLevel,
          'session_mode': sessionMode,
          'marking_source': markingSource,
          'feature_name': featureName,
          'source': source,
        });
      case ConfidenceTrackingToggledEvent(:final enabled):
        await _log('confidence_tracking_toggled', {
          'enabled': enabled ? 1 : 0,
        });
      case UspSessionCoachCtaTappedEvent(:final action):
        await _log('usp_coach_cta', {'action': action});
      case AppNotificationOpenEvent(:final channel, :final kind):
        await _log('app_notification_open', {
          'channel': channel,
          'kind': kind,
        });
      case FirstInsightSeenEvent():
        await _log('first_insight_seen', const {});
      case InsightsDashboardOpenedEvent():
        await _log('insights_dashboard_opened', const {});
      case TrapAwarenessOpenedEvent():
        await _log('trap_awareness_opened', const {});
      case RevisionRecommendationClickedEvent(:final source):
        await _log('revision_recommendation_clicked', {
          'source': source,
        });
      case RiskCardClickedEvent(:final subject, :final riskTier):
        await _log('risk_card_clicked', {
          'subject': subject,
          'risk_tier': riskTier,
        });
      case GetStartedCardShownEvent():
        await _log('get_started_card_shown', const {});
      case GetStartedCardTappedEvent(:final subject, :final source):
        await _log('get_started_card_tapped', {
          if (subject case final s?) 'subject': s,
          if (source case final src?) 'source': src,
        });
      case DidYouKnowShownEvent(:final cardId):
        await _log('did_you_know_shown', {'card_id': cardId});
      case DidYouKnowDismissedEvent(:final cardId):
        await _log('did_you_know_dismissed', {'card_id': cardId});
      case DidYouKnowCtaTappedEvent(:final cardId):
        await _log('did_you_know_cta_tapped', {'card_id': cardId});
      case GameScreenOpenedEvent(:final gameName):
        await _log('game_screen_opened', {'game_name': gameName});
      case GameStartedEvent(:final gameName, :final totalRounds):
        await _log('game_started', {
          'game_name': gameName,
          if (totalRounds case final t?) 'total_rounds': t,
        });
      case GameRoundFinishedEvent(
          :final gameName,
          :final correctCount,
          :final totalRounds,
        ):
        await _log('game_round_finished', {
          'game_name': gameName,
          'correct_count': correctCount,
          'total_rounds': totalRounds,
        });
      case MemoryPairsGameDiscoveredEvent():
        await _log('memory_pairs_game_discovered', const {});
      case MemoryPairsGamePlayedEvent(:final setId, :final difficulty):
        await _log('memory_pairs_game_played', {
          'set_id': setId,
          'difficulty': difficulty,
        });
      case DailyDrillCardShownEvent():
        await _log('daily_drill_card_shown', const {});
      case DailyDrillStartedEvent(
          :final subject,
          :final source,
          :final completedToday,
        ):
        await _log('daily_drill_started', {
          'subject': subject,
          'source': source,
          'completed_today': completedToday,
        });
      case DailyDrillSubjectChangedEvent(:final subject):
        await _log('daily_drill_subject_changed', {'subject': subject});
      case SessionInsightCaseShownEvent(
          :final caseName,
          :final sureWrong,
          :final eduWrong,
        ):
        await _log('session_insight_case_shown', {
          'case': caseName,
          'sure_wrong': sureWrong,
          'edu_wrong': eduWrong,
        });
    }
  }

  Future<void> _setPushAlertsUserProperty(String status) async {
    await _analytics.setUserProperty(
      name: 'push_alerts',
      value: switch (status) {
        'authorized' => 'on',
        'provisional' => 'on',
        'not_determined' => 'not_determined',
        'denied' => 'off',
        'web_authorized' => 'on',
        _ => 'unknown',
      },
    );
  }

  Future<void> _log(String name, Map<String, Object> params) async {
    final uid = _userId;
    final merged = <String, Object>{
      ...params,
      if (uid case final u?) 'user_id': u,
    };
    await _analytics.logEvent(name: name, parameters: merged);
  }
}
