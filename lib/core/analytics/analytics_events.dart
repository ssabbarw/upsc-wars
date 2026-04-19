/// Strongly typed analytics envelope. Add new variants only when product needs
/// custom payloads; feature usage uses [FeatureUsageEvent] subclasses.
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

final class AppOpenedEvent extends AnalyticsEvent {
  const AppOpenedEvent();
}

final class SessionStartedEvent extends AnalyticsEvent {
  const SessionStartedEvent();
}

final class SessionEndedEvent extends AnalyticsEvent {
  const SessionEndedEvent();
}

final class ScreenViewedEvent extends AnalyticsEvent {
  const ScreenViewedEvent({required this.screenName});

  final String screenName;
}

sealed class FeatureUsageEvent extends AnalyticsEvent {
  const FeatureUsageEvent({
    required this.featureName,
    required this.subject,
    this.topic,
    this.difficulty,
    required this.source,
  });

  final String featureName;
  final String subject;
  final String? topic;
  final String? difficulty;
  final String source;
}

final class FeatureViewedEvent extends FeatureUsageEvent {
  const FeatureViewedEvent({
    required super.featureName,
    required super.subject,
    super.topic,
    super.difficulty,
    required super.source,
  });
}

final class FeatureStartedEvent extends FeatureUsageEvent {
  const FeatureStartedEvent({
    required super.featureName,
    required super.subject,
    super.topic,
    super.difficulty,
    required super.source,
  });
}

final class FeatureCompletedEvent extends FeatureUsageEvent {
  const FeatureCompletedEvent({
    required super.featureName,
    required super.subject,
    super.topic,
    super.difficulty,
    required super.source,
  });
}

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

final class PaywallViewedEvent extends AnalyticsEvent {
  const PaywallViewedEvent({
    required this.sourceFeature,
    this.planType,
  });

  final String sourceFeature;
  final String? planType;
}

final class SubscriptionStartedEvent extends AnalyticsEvent {
  const SubscriptionStartedEvent({
    required this.sourceFeature,
    this.planType,
  });

  final String sourceFeature;
  final String? planType;
}

final class SubscriptionCompletedEvent extends AnalyticsEvent {
  const SubscriptionCompletedEvent({
    required this.sourceFeature,
    this.planType,
  });

  final String sourceFeature;
  final String? planType;
}

final class StreakContinuedEvent extends AnalyticsEvent {
  const StreakContinuedEvent({required this.streakLength});

  final int streakLength;
}

final class RevisionCompletedEvent extends AnalyticsEvent {
  const RevisionCompletedEvent({
    required this.questionsCount,
    required this.subject,
  });

  final int questionsCount;
  final String subject;
}

/// One event per MCQ session when the player enters the active test UI
/// (home flow or battle). Firebase event count on `mcq_test_session_started`
/// is the global total of tests attempted.
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

/// Host finished the `sendBattleInvite` callable (success or structured
/// failure). [kind] is `push_ok`, `no_token`, `send_failed`, or
/// `transport_error`. In GA4, count events where `kind` != `transport_error`
/// for “invite reached the backend”; use `kind` == `push_ok` for FCM
/// delivered.
final class BattleInviteOutcomeEvent extends AnalyticsEvent {
  const BattleInviteOutcomeEvent({required this.kind});

  final String kind;
}

/// Guest completed the join flow and entered the battle lobby (invite accepted).
final class BattleInviteAcceptedEvent extends AnalyticsEvent {
  const BattleInviteAcceptedEvent();
}
