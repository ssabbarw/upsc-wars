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
