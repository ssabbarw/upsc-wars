class SessionResult {
  const SessionResult({
    required this.sessionId,
    required this.subjectSlug,
    required this.topicSlug,
    required this.subTopicSlug,
    required this.mode,
    required this.createdAt,
    required this.completedAt,
    required this.timeLimitSecs,
    required this.questionCount,
    required this.correct,
    required this.wrong,
    required this.unattempted,
    required this.timedOut,
    required this.accuracy,
    required this.accuracyTier,
    required this.netScore,
    required this.avgTimeSpentSecs,
    required this.totalTimeSpentSecs,
    required this.language,
  });
  final String sessionId;
  final String subjectSlug;
  final String? topicSlug;
  final String? subTopicSlug;
  final String mode;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? timeLimitSecs;
  final int questionCount;
  final int correct;
  final int wrong;
  final int unattempted;
  final int timedOut;
  final double accuracy;
  final String accuracyTier;
  final double netScore;
  final double? avgTimeSpentSecs;
  /// Sum of per-question time spent (for timed session summary).
  final int totalTimeSpentSecs;
  final String language;
}
