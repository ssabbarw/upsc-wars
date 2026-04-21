/// Stored on the local session row ([SessionConfig.analyticsFeatureKey]) so
/// results can finish the Firestore open-challenge flow.
abstract final class OpenChallengeAnalytics {
  OpenChallengeAnalytics._();

  static const create = 'open_challenge_create';
  static const accept = 'open_challenge_accept';
}
