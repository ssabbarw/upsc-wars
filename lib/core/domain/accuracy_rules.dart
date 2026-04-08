import 'entities/accuracy_display_tier.dart';

/// Central place for accuracy presentation rules (Phase 2 + .cursor/rules).
abstract final class AccuracyRules {
  AccuracyRules._();

  static AccuracyDisplayTier tierFor({
    required int attemptCount,
    required double? accuracyPercent,
  }) {
    if (attemptCount == 0) return AccuracyDisplayTier.dash;
    if (attemptCount < 10) return AccuracyDisplayTier.mutedLowAttempts;
    final a = accuracyPercent ?? 0;
    if (a >= 70) return AccuracyDisplayTier.high;
    if (a >= 55) return AccuracyDisplayTier.medium;
    return AccuracyDisplayTier.low;
  }

  static double? accuracyPercentOrNull({
    required int attemptCount,
    required int correctCount,
  }) {
    if (attemptCount == 0) return null;
    return (correctCount / attemptCount) * 100;
  }
}
