import '../../../core/database/user_db.dart';

/// Result for a single trap type's performance stats.
class TrapBlindSpotRow {
  const TrapBlindSpotRow({
    required this.trapType,
    required this.totalAttempts,
    required this.wrongCount,
  });

  final String trapType;
  final int totalAttempts;
  final int wrongCount;

  int get correctCount => totalAttempts - wrongCount;

  /// Accuracy as a percentage (0–100). Returns 0 if [totalAttempts] is 0.
  double get accuracyPercent =>
      totalAttempts > 0 ? (correctCount / totalAttempts) * 100 : 0;

  /// Readable display name: underscores → spaces, title-cased.
  String get displayName {
    return trapType
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Risk tier for a topic or the overall subject.
enum RiskTier { low, medium, high }

extension RiskTierX on RiskTier {
  String get label {
    switch (this) {
      case RiskTier.low:
        return 'Low Risk';
      case RiskTier.medium:
        return 'Medium Risk';
      case RiskTier.high:
        return 'High Risk';
    }
  }

  String get emoji {
    switch (this) {
      case RiskTier.low:
        return '🟢';
      case RiskTier.medium:
        return '🟡';
      case RiskTier.high:
        return '🔴';
    }
  }
}

RiskTier riskTierForWrongCount(int count) {
  if (count >= 8) return RiskTier.high;
  if (count >= 3) return RiskTier.medium;
  return RiskTier.low;
}

/// Aggregated insights for a single subject.
class SubjectInsights {
  const SubjectInsights({
    required this.wrongCountLast30Days,
    required this.topicRisks,
    required this.trapBlindSpots,
  });

  /// Wrong answers in the last 30 days for this subject.
  final int wrongCountLast30Days;

  /// Top-5 topics sorted by [UserTopicStat.wrongAttempts] descending,
  /// filtered to only topics with at least 1 wrong attempt.
  final List<UserTopicStat> topicRisks;

  /// Trap types sorted by wrong count descending,
  /// filtered to trap types with at least 2 attempts.
  final List<TrapBlindSpotRow> trapBlindSpots;

  RiskTier get overallRiskTier => riskTierForWrongCount(wrongCountLast30Days);

  bool get hasTopicData => topicRisks.isNotEmpty;
  bool get hasTrapData => trapBlindSpots.isNotEmpty;
}
