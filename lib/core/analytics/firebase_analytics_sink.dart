import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_events.dart';
import 'analytics_sink.dart';

/// Sends curated events to Firebase Analytics. No other layer imports
/// [FirebaseAnalytics] directly.
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
    }
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
