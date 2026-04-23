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

/// OS push notification permission as reported by
/// [FirebaseMessaging.instance.getNotificationSettings] (one snapshot, e.g. on
/// app resume). [status] is a stable snake_case label: `authorized`,
/// `denied`, `provisional`, `not_determined`, or `web_authorized` on web.
final class PushNotificationStatusSnapshotEvent extends AnalyticsEvent {
  const PushNotificationStatusSnapshotEvent({
    required this.status,
    required this.allowsPush,
  });

  final String status;
  final bool allowsPush;
}

/// Time spent on a horizontal onboarding step before leaving (swipe) or
/// finishing the flow. [step] is one of: `score_story`, `mechanism`,
/// `diagnosis`, `loop`.
final class OnboardingStepDurationEvent extends AnalyticsEvent {
  const OnboardingStepDurationEvent({
    required this.step,
    required this.durationMs,
  });

  final String step;
  final int durationMs;
}

/// User swiped the vertical “Typical test series stats / swipe up”
/// [PageView] on the first onboarding page to the hidden “UPSC Wars advantage”
/// slide (at least once; event fires on first reach only per screen visit).
final class OnboardingRevealTrialSwipedEvent extends AnalyticsEvent {
  const OnboardingRevealTrialSwipedEvent();
}

/// Fires once when the first-run [OnboardingFlowScreen] is opened (funnel start).
final class OnboardingFlowOpenedEvent extends AnalyticsEvent {
  const OnboardingFlowOpenedEvent();
}

/// User tapped **Get started** on the last step; [totalDurationMs] is time from
/// [OnboardingFlowOpenedEvent] to completion (entire flow).
final class OnboardingFlowCompletedEvent extends AnalyticsEvent {
  const OnboardingFlowCompletedEvent({required this.totalDurationMs});

  final int totalDurationMs;
}

/// Deferred notification education bottom sheet closed after 1st/2nd impression.
/// [source] is `post_test` or `community_signin`. [tappedEnableNotifications] is
/// true when the user hit “Turn on notifications” (we then may show the system dialog).
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

/// Fires the first time any local session is marked `completed` (D1 “activation”
/// signal; includes practice and similar flows through [submitSession]).
final class FirstSessionCompletedEvent extends AnalyticsEvent {
  const FirstSessionCompletedEvent();
}
