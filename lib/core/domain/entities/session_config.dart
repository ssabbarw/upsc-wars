class SessionConfig {
  const SessionConfig({
    required this.subjectSlug,
    this.topicSlug,
    this.subTopicSlug,
    required this.mode,
    required this.questionCount,
    required this.isTimed,
    this.timeLimitSecs,
    required this.language,
  });

  final String subjectSlug;
  final String? topicSlug;
  final String? subTopicSlug;

  /// 'exam' | 'learning'
  final String mode;
  final int questionCount;
  final bool isTimed;

  /// Exam: total seconds when timed; Learning: per-question limit (45|60|120).
  final int? timeLimitSecs;
  final String language;
}
