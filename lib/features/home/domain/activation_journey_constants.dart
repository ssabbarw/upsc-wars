/// Home activation checklist — first-session journey after onboarding.
abstract final class ActivationJourneyConstants {
  ActivationJourneyConstants._();

  /// Scored answers (correct + wrong) needed for the *full*, trustworthy
  /// confidence / Danger Zone map.
  static const confidenceMapUnlockAttempts = 50;

  /// Scored answers needed to preview an *early* Danger Zone read. We surface
  /// the shape of the payoff before the full map so the differentiator isn't
  /// invisible during the churn-prone early window.
  static const confidenceMapPreviewAttempts = 20;
}
