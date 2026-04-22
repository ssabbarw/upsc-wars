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
    this.dangerZoneWrongCount = 0,
    this.dangerZoneMarksEstimate = 0.0,
    this.confidenceSureTotal = 0,
    this.confidenceSureCorrect = 0,
    this.confidenceIntelligentTotal = 0,
    this.confidenceIntelligentCorrect = 0,
    this.confidencePureTotal = 0,
    this.confidencePureCorrect = 0,
    this.analyticsFeatureKey,
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

  /// Wrong answers where confidence was very sure or somewhat sure.
  final int dangerZoneWrongCount;

  /// Approximate marks lost at Prelims negative marking (-0.66 per question).
  final double dangerZoneMarksEstimate;

  /// Scored rows with confidence == sure ([AnswerConfidence.verySure]).
  final int confidenceSureTotal;
  final int confidenceSureCorrect;

  /// Scored rows with educated guess ([AnswerConfidence.somewhatSure]).
  final int confidenceIntelligentTotal;
  final int confidenceIntelligentCorrect;

  /// Scored rows with pure guess ([AnswerConfidence.guessing]).
  final int confidencePureTotal;
  final int confidencePureCorrect;

  /// When set (e.g. `mcq_battle`), identifies the session's originating feature.
  final String? analyticsFeatureKey;
}
