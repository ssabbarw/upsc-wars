class SessionSummary {
  const SessionSummary({
    required this.sessionId,
    required this.subjectSlug,
    required this.topicSlug,
    required this.mode,
    required this.status,
    required this.createdAt,
    required this.questionCount,
    required this.correct,
    required this.wrong,
    required this.accuracy,
    required this.accuracyTier,
    required this.netScore,
    required this.avgTimeSpentSecs,
  });
  final String sessionId;
  final String subjectSlug;
  final String? topicSlug;
  final String mode;
  final String status;
  final DateTime createdAt;
  final int questionCount;
  final int? correct;
  final int? wrong;
  final double? accuracy;
  final String? accuracyTier;
  final double? netScore;
  final double? avgTimeSpentSecs;
}
