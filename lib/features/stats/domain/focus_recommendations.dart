import '../../test_series/domain/series_rules.dart';

enum FocusKind { weak, shaky, untouched }

class FocusCandidate {
  const FocusCandidate({
    required this.subject,
    required this.topic,
    required this.displayName,
    required this.poolSize,
    required this.answered,
    required this.correct,
  });

  final String subject;
  final String topic;
  final String displayName;
  final int poolSize;
  final int answered;
  final int correct;

  double? get accuracyPercent =>
      answered <= 0 ? null : (correct / answered) * 100;

  double? get coveragePercent =>
      poolSize <= 0 ? null : (answered / poolSize) * 100;
}

class FocusRecommendation {
  const FocusRecommendation({
    required this.subject,
    required this.topic,
    required this.displayName,
    required this.kind,
    required this.poolSize,
  });

  final String subject;
  final String topic;
  final String displayName;
  final FocusKind kind;
  final int poolSize;
}

/// Where to practise next.
///
/// Weak topics (enough answers, accuracy under 60%) come first, then shaky
/// ones (under [SeriesRules.safeAccuracyPercent]), then large untouched pools.
List<FocusRecommendation> focusRecommendations(
  List<FocusCandidate> topics, {
  String? subject,
  int limit = 3,
}) {
  final pool = subject == null
      ? topics
      : topics.where((t) => t.subject == subject).toList();

  FocusKind? kindOf(FocusCandidate topic) {
    final accuracy = topic.accuracyPercent;
    if (topic.answered >= SeriesRules.safeMinQuestions && accuracy != null) {
      if (accuracy < 60) return FocusKind.weak;
      if (accuracy < SeriesRules.safeAccuracyPercent) return FocusKind.shaky;
    }
    final coverage = topic.coveragePercent;
    if (topic.poolSize >= 25 && coverage != null && coverage < 10) {
      return FocusKind.untouched;
    }
    return null;
  }

  const rank = {FocusKind.weak: 0, FocusKind.shaky: 1, FocusKind.untouched: 2};

  final picked = <({FocusCandidate topic, FocusKind kind})>[];
  for (final topic in pool) {
    final kind = kindOf(topic);
    if (kind != null) picked.add((topic: topic, kind: kind));
  }

  picked.sort((a, b) {
    final byKind = rank[a.kind]!.compareTo(rank[b.kind]!);
    if (byKind != 0) return byKind;
    return b.topic.poolSize.compareTo(a.topic.poolSize);
  });

  return [
    for (final item in picked.take(limit))
      FocusRecommendation(
        subject: item.topic.subject,
        topic: item.topic.topic,
        displayName: item.topic.displayName,
        kind: item.kind,
        poolSize: item.topic.poolSize,
      ),
  ];
}
