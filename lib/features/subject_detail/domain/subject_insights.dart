/// Risk tier from percentile bands within a subject (topic ranking).
enum RiskTier { low, medium, high }

extension RiskTierX on RiskTier {
  String get label {
    switch (this) {
      case RiskTier.low:
        return 'Lower risk';
      case RiskTier.medium:
        return 'Medium risk';
      case RiskTier.high:
        return 'Higher risk';
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

/// One topic's Danger Zone frequency in the ranking window, with a tier.
class TopicPercentileRow {
  const TopicPercentileRow({
    required this.topic,
    required this.dangerCount,
    required this.tier,
  });

  final String topic;
  final int dangerCount;
  final RiskTier tier;
}

/// Subject-scoped Danger Zone + topic ranking (last 30 days).
class SubjectInsights {
  const SubjectInsights({
    required this.dangerZoneCountLast30Days,
    required this.dangerZoneSureWrongCountLast30Days,
    required this.dangerZoneEducatedGuessWrongCountLast30Days,
    required this.dangerZoneMarksLast30,
    required this.topicPercentiles,
  });

  final int dangerZoneCountLast30Days;
  /// Wrong attempts where confidence was "Sure" (`very_sure` in the DB).
  final int dangerZoneSureWrongCountLast30Days;
  /// Wrong attempts where confidence was "Educated guess" (`somewhat_sure`).
  final int dangerZoneEducatedGuessWrongCountLast30Days;
  final double dangerZoneMarksLast30;
  final List<TopicPercentileRow> topicPercentiles;

  bool get hasTopicData => topicPercentiles.isNotEmpty;

  bool get isWellCalibratedThisMonth => dangerZoneCountLast30Days == 0;
}

/// Top ~20% of topics by danger count → high, next ~30% → medium, rest low.
List<TopicPercentileRow> topicRowsWithPercentileTiers(
  List<({String topic, int dangerCount})> sortedDesc,
) {
  if (sortedDesc.isEmpty) return [];
  final n = sortedDesc.length;
  final redN = n == 1 ? 1 : (n * 0.2).ceil().clamp(1, n);
  final yellowN = (n * 0.3).ceil().clamp(0, n);
  final out = <TopicPercentileRow>[];
  for (var i = 0; i < n; i++) {
    final row = sortedDesc[i];
    final tier =
        i < redN
            ? RiskTier.high
            : i < redN + yellowN
                ? RiskTier.medium
                : RiskTier.low;
    out.add(
      TopicPercentileRow(
        topic: row.topic,
        dangerCount: row.dangerCount,
        tier: tier,
      ),
    );
  }
  return out;
}

/// Fixed bands for cross-subject overview rows (not percentile-based).
RiskTier riskTierForWrongCount(int count) {
  if (count >= 8) return RiskTier.high;
  if (count >= 3) return RiskTier.medium;
  return RiskTier.low;
}
