class SessionConfig {
  const SessionConfig({
    required this.subject,
    this.topic,
    this.subTopic,
    required this.mode,
    required this.questionCount,
    required this.isTimed,
    this.timeLimitSecs,
    required this.language,
  });

  final String subject;
  final String? topic;
  final String? subTopic;

  /// 'exam' | 'learning'
  final String mode;
  final int questionCount;
  final bool isTimed;

  /// Exam: total seconds when timed; Learning: per-question limit (45|60|120).
  final int? timeLimitSecs;
  final String language;
}
