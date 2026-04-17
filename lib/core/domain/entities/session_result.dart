class SessionResult {
  const SessionResult({
    required this.sessionId,
    required this.subject,
    required this.topic,
    required this.subTopic,
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
    this.graduatedCount = 0,
  });
  final String sessionId;
  final String subject;
  final String? topic;
  final String? subTopic;
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
  /// Number of revision queue questions graduated during this session.
  /// Only populated for sessions with subject == 'revision_quick'.
  final int graduatedCount;
}
