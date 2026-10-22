import 'analytics_events.dart';

/// One named product event ready for a sink (GA4 name + params).
final class AnalyticsMappedEvent {
  const AnalyticsMappedEvent(this.name, [this.params = const {}]);

  final String name;
  final Map<String, Object> params;
}

/// Shared [AnalyticsEvent] → sink payload mapping used by Firebase and PostHog.
final class AnalyticsEventMapping {
  const AnalyticsEventMapping({
    required this.events,
    this.userProperties = const {},
  });

  final List<AnalyticsMappedEvent> events;
  final Map<String, String> userProperties;
}

/// Maps a typed [AnalyticsEvent] to GA4-compatible event names / parameters
/// (and optional user properties). Keep product meanings on the event classes
/// in [analytics_events.dart]; this file is only the wire format.
AnalyticsEventMapping mapAnalyticsEvent(AnalyticsEvent event) {
  switch (event) {
    case AppOpenedEvent(:final entrySource, :final entryDetail):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('app_opened', {
            'entry_source': entrySource,
            if (entryDetail case final d?) 'entry_detail': d,
          }),
        ],
      );
    case SessionStartedEvent(:final entrySource, :final entryDetail):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('session_started', {
            'entry_source': entrySource,
            if (entryDetail case final d?) 'entry_detail': d,
          }),
        ],
      );
    case SessionEndedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('session_ended')],
      );
    case ScreenViewedEvent(:final screenName):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('screen_viewed', {'screen_name': screenName}),
        ],
      );
    case ScreenDwellEndedEvent(
      :final screenName,
      :final durationMs,
      :final endKind,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('screen_dwell_ended', {
            'screen_name': screenName,
            'duration_ms': durationMs,
            'end_kind': endKind,
          }),
        ],
      );
    case ScreenFlowActionEvent(
      :final screenName,
      :final actionId,
      :final actionKind,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('screen_flow_action', {
            'screen_name': screenName,
            'action_id': actionId,
            'action_kind': actionKind,
          }),
        ],
      );
    case FeatureViewedEvent(
      :final featureName,
      :final subject,
      :final topic,
      :final difficulty,
      :final source,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('feature_viewed', {
            'feature_name': featureName,
            'subject': subject,
            if (topic case final t?) 'topic': t,
            if (difficulty case final d?) 'difficulty': d,
            'source': source,
          }),
        ],
      );
    case FeatureStartedEvent(
      :final featureName,
      :final subject,
      :final topic,
      :final difficulty,
      :final source,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('feature_started', {
            'feature_name': featureName,
            'subject': subject,
            if (topic case final t?) 'topic': t,
            if (difficulty case final d?) 'difficulty': d,
            'source': source,
          }),
        ],
      );
    case FeatureCompletedEvent(
      :final featureName,
      :final subject,
      :final topic,
      :final difficulty,
      :final source,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('feature_completed', {
            'feature_name': featureName,
            'subject': subject,
            if (topic case final t?) 'topic': t,
            if (difficulty case final d?) 'difficulty': d,
            'source': source,
          }),
        ],
      );
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
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('question_attempted', {
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
          }),
        ],
      );
    case StreakContinuedEvent(:final streakLength):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('streak_continued', {
            'streak_length': streakLength,
          }),
        ],
      );
    case RevisionStartedEvent(:final questionsCount, :final subject):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('revision_started', {
            'questions_count': questionsCount,
            'subject': subject,
          }),
        ],
      );
    case RevisionCompletedEvent(:final questionsCount, :final subject):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('revision_completed', {
            'questions_count': questionsCount,
            'subject': subject,
          }),
        ],
      );
    case McqTestSessionStartedEvent(
      :final subject,
      :final topic,
      :final analyticsFeatureKey,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('mcq_test_session_started', {
            'subject': subject,
            if (topic case final t?) 'topic': t,
            if (analyticsFeatureKey case final k?) 'analytics_feature_key': k,
          }),
        ],
      );
    case BattleInviteOutcomeEvent(:final kind):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('battle_invite_outcome', {'kind': kind}),
        ],
      );
    case BattleInviteAcceptedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('battle_invite_accepted')],
      );
    case PushNotificationStatusSnapshotEvent(:final status, :final allowsPush):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('push_permission_snapshot', {
            'status': status,
            'allows_push': allowsPush ? 1 : 0,
          }),
        ],
        userProperties: {'push_alerts': _pushAlertsValue(status)},
      );
    case PushPermissionPromptResultEvent(
      :final status,
      :final allowsPush,
      :final source,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('push_permission_prompt_result', {
            'status': status,
            'allows_push': allowsPush ? 1 : 0,
            'source': source,
          }),
        ],
        userProperties: {'push_alerts': _pushAlertsValue(status)},
      );
    case PushPermissionGrantedEvent(:final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('push_permission_granted', {'source': source}),
        ],
      );
    case DeferredPushEducationModalShownEvent(:final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('deferred_push_education_shown', {
            'source': source,
          }),
        ],
      );
    case OnboardingStepDurationEvent(:final step, :final durationMs):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('onboarding_step_duration', {
            'step': step,
            'duration_ms': durationMs,
          }),
        ],
      );
    case OnboardingFlowOpenedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('onboarding_flow_opened')],
      );
    case OnboardingFlowCompletedEvent(:final totalDurationMs):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('onboarding_flow_completed', {
            'total_duration_ms': totalDurationMs,
          }),
        ],
      );
    case OnboardingExitedIncompleteEvent(
      :final highestStep,
      :final lastStep,
      :final elapsedMs,
      :final reachedLastStep,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('onboarding_exited_incomplete', {
            'highest_step': highestStep,
            'last_step': lastStep,
            'elapsed_ms': elapsedMs,
            'reached_last_step': reachedLastStep ? 1 : 0,
          }),
        ],
      );
    case DeferredPushEducationModalOutcomeEvent(
      :final source,
      :final modalIndex,
      :final tappedEnableNotifications,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('deferred_push_education_outcome', {
            'source': source,
            'modal_index': modalIndex,
            'tapped_enable': tappedEnableNotifications ? 1 : 0,
          }),
        ],
      );
    case DeferredPushHomeNudgeShownEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('deferred_push_home_nudge_shown')],
      );
    case DeferredPushHomeNudgeTapEnableEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('deferred_push_home_nudge_tap_enable')],
      );
    case DeferredPushHomeNudgeDismissedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('deferred_push_home_nudge_dismissed')],
      );
    case FirstSessionCompletedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('first_session_completed')],
      );
    case TestSessionAbandonedEvent(
      :final featureName,
      :final subject,
      :final topic,
      :final source,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('test_session_abandoned', {
            'feature_name': featureName,
            'subject': subject,
            if (topic case final t?) 'topic': t,
            'source': source,
          }),
        ],
      );
    case ActivationMilestoneEvent(:final milestoneId):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('activation_milestone', {
            'milestone_id': milestoneId,
          }),
        ],
      );
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
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('usp_session_result', {
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
          }),
        ],
      );
    case ConfidenceMarkedEvent(
      :final confidenceLevel,
      :final sessionMode,
      :final markingSource,
      :final featureName,
      :final source,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('confidence_marked', {
            'confidence_level': confidenceLevel,
            'session_mode': sessionMode,
            'marking_source': markingSource,
            'feature_name': featureName,
            'source': source,
          }),
        ],
      );
    case ConfidenceTrackingToggledEvent(:final enabled):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('confidence_tracking_toggled', {
            'enabled': enabled ? 1 : 0,
          }),
        ],
      );
    case UspSessionCoachCtaTappedEvent(:final action):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('usp_coach_cta', {'action': action}),
        ],
      );
    case AppNotificationOpenEvent(:final channel, :final kind):
      final notificationParams = <String, Object>{
        'channel': channel,
        'kind': kind,
      };
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('app_notification_open', notificationParams),
          AnalyticsMappedEvent('notification_opened', notificationParams),
        ],
      );
    case AccountSignedInEvent(:final method):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('account_signed_in', {
            if (method case final m?) 'method': m,
          }),
        ],
      );
    case FirstInsightSeenEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('first_insight_seen')],
      );
    case InsightsDashboardOpenedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('insights_dashboard_opened')],
      );
    case TrapAwarenessOpenedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('trap_awareness_opened')],
      );
    case RevisionRecommendationClickedEvent(:final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('revision_recommendation_clicked', {
            'source': source,
          }),
        ],
      );
    case RiskCardClickedEvent(:final subject, :final riskTier):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('risk_card_clicked', {
            'subject': subject,
            'risk_tier': riskTier,
          }),
        ],
      );
    case GetStartedCardShownEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('get_started_card_shown')],
      );
    case GetStartedCardTappedEvent(:final subject, :final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('get_started_card_tapped', {
            if (subject case final s?) 'subject': s,
            if (source case final src?) 'source': src,
          }),
        ],
      );
    case GetStartedCardSnoozedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('get_started_card_snoozed')],
      );
    case ActivationJourneyShownEvent(
      :final todo1Done,
      :final scoredAttempts,
      :final todo2Unlocked,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('activation_journey_shown', {
            'todo1_done': todo1Done ? 1 : 0,
            'scored_attempts': scoredAttempts,
            'todo2_unlocked': todo2Unlocked ? 1 : 0,
          }),
        ],
      );
    case ActivationJourneyTodoTappedEvent(:final todoIndex):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('activation_journey_todo_tapped', {
            'todo_index': todoIndex,
          }),
        ],
      );
    case ActivationJourneySnoozedEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('activation_journey_snoozed')],
      );
    case DemoTestAttemptedEvent(:final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('demo_test_attempted', {'source': source}),
        ],
      );
    case DemoTestDismissedEvent(:final strike):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('demo_test_dismissed', {'strike': strike}),
        ],
      );
    case GameScreenOpenedEvent(:final gameName):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('game_screen_opened', {'game_name': gameName}),
        ],
      );
    case GameStartedEvent(:final gameName, :final totalRounds):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('game_started', {
            'game_name': gameName,
            if (totalRounds case final t?) 'total_rounds': t,
          }),
        ],
      );
    case GameRoundFinishedEvent(
      :final gameName,
      :final correctCount,
      :final totalRounds,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('game_round_finished', {
            'game_name': gameName,
            'correct_count': correctCount,
            'total_rounds': totalRounds,
          }),
        ],
      );
    case MemoryPairsGameDiscoveredEvent():
      return const AnalyticsEventMapping(
        events: [AnalyticsMappedEvent('memory_pairs_game_discovered')],
      );
    case MemoryPairsGamePlayedEvent(:final setId, :final difficulty):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('memory_pairs_game_played', {
            'set_id': setId,
            'difficulty': difficulty,
          }),
        ],
      );
    case DailyDrillStartedEvent(
      :final subject,
      :final source,
      :final completedToday,
      :final pool,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_drill_started', {
            'subject': subject,
            'source': source,
            'completed_today': completedToday,
            if (pool != null) 'pool': pool,
          }),
        ],
      );
    case DailyDrillSubjectChangedEvent(:final subject):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_drill_subject_changed', {
            'subject': subject,
          }),
        ],
      );
    case SessionInsightCaseShownEvent(
      :final caseName,
      :final sureWrong,
      :final eduWrong,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('session_insight_case_shown', {
            'case': caseName,
            'sure_wrong': sureWrong,
            'edu_wrong': eduWrong,
          }),
        ],
      );
    case DailyWarHomeShownEvent(:final dateId, :final phase, :final isGrand):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_war_home_shown', {
            'date_id': dateId,
            'phase': phase,
            'is_grand': isGrand ? 1 : 0,
          }),
        ],
      );
    case DailyWarAttemptedEvent(:final dateId, :final mode, :final isGrand):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_war_attempted', {
            'date_id': dateId,
            'mode': mode,
            'is_grand': isGrand ? 1 : 0,
          }),
        ],
        userProperties: const {'daily_war_player': 'yes'},
      );
    case DailyWarSubmittedEvent(
      :final dateId,
      :final mode,
      :final isGrand,
      :final score,
    ):
      final warSubmittedParams = <String, Object>{
        'date_id': dateId,
        'mode': mode,
        'is_grand': isGrand ? 1 : 0,
        'score_hundredths': (score * 100).round(),
      };
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_war_submitted', warSubmittedParams),
          AnalyticsMappedEvent(
            'daily_static_war_completed',
            warSubmittedParams,
          ),
        ],
      );
    case DailyCaAttemptedEvent(:final dateId, :final mode):
      final caStartedParams = <String, Object>{'date_id': dateId, 'mode': mode};
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_ca_attempted', caStartedParams),
          AnalyticsMappedEvent(
            'daily_current_affairs_started',
            caStartedParams,
          ),
        ],
        userProperties: const {'daily_ca_player': 'yes'},
      );
    case DailyCaSubmittedEvent(:final dateId, :final mode, :final score):
      final caSubmittedParams = <String, Object>{
        'date_id': dateId,
        'mode': mode,
        'score_hundredths': (score * 100).round(),
      };
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('daily_ca_submitted', caSubmittedParams),
          AnalyticsMappedEvent(
            'daily_current_affairs_completed',
            caSubmittedParams,
          ),
        ],
      );
    case CaShotHubOpenedEvent(:final shotCount, :final doneCount):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('ca_shot_hub_opened', {
            'shot_count': shotCount,
            'done_count': doneCount,
          }),
        ],
      );
    case CaShotNotifOpenedEvent(:final pulseId, :final channel):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('ca_shot_notif_opened', {
            'pulse_id': pulseId,
            'channel': channel,
          }),
        ],
      );
    case CaShotOpenedEvent(:final pulseId, :final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('ca_shot_opened', {
            'pulse_id': pulseId,
            'source': source,
          }),
        ],
      );
    case CaShotSummaryViewedEvent(:final pulseId, :final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('ca_shot_summary_viewed', {
            'pulse_id': pulseId,
            'source': source,
          }),
        ],
      );
    case CaShotMcqOpenedEvent(
      :final pulseId,
      :final source,
      :final alreadyAttempted,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('ca_shot_mcq_opened', {
            'pulse_id': pulseId,
            'source': source,
            'already_attempted': alreadyAttempted ? 1 : 0,
          }),
        ],
      );
    case CaShotAttemptedEvent(:final pulseId, :final source, :final correct):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('ca_shot_attempted', {
            'pulse_id': pulseId,
            'source': source,
            'correct': correct ? 1 : 0,
          }),
        ],
      );
    case ExplanationSectionViewedEvent(:final section, :final source):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('explanation_section_viewed', {
            'section': section,
            'source': source,
          }),
        ],
      );
    case DemoReviewOpenedEvent(:final kind):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('demo_review_opened', {'kind': kind}),
        ],
      );
    case PostDemoExploreEvent(:final surface):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('post_demo_explore', {'surface': surface}),
        ],
      );
    case DemoTestSubmittedEvent(
      :final attempted,
      :final total,
      :final attemptBand,
    ):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('demo_test_submitted', {
            'attempted': attempted,
            'total': total,
            'attempt_band': attemptBand,
          }),
        ],
      );
    case PracticeTestStartedEvent(:final testId):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('practice_test_start', {'test_id': testId}),
        ],
      );
    case PracticeTestCompletedEvent(:final testId):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('practice_test_complete', {'test_id': testId}),
        ],
      );
    case StatsViewedEvent(:final subject):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('stats_view', {'subject': subject}),
        ],
      );
    case StatsFocusTapEvent(:final subject, :final topic):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('stats_focus_tap', {
            'subject': subject,
            'topic': topic,
          }),
        ],
      );
    case AppLanguageSwitchedEvent(:final fromLanguage, :final toLanguage):
      return AnalyticsEventMapping(
        events: [
          AnalyticsMappedEvent('app_language_switched', {
            'from_language': fromLanguage,
            'to_language': toLanguage,
          }),
        ],
        userProperties: {'app_language': toLanguage},
      );
  }
}

String _pushAlertsValue(String status) {
  return switch (status) {
    'authorized' => 'on',
    'provisional' => 'on',
    'not_determined' => 'not_determined',
    'denied' => 'off',
    'web_authorized' => 'on',
    _ => 'unknown',
  };
}
