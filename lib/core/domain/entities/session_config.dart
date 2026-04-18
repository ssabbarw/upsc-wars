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
    this.specificQuestionUuids,
    this.analyticsFeatureKey,
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

  /// When set, session is built from exactly these UUIDs (in order) instead of
  /// querying by subject/topic.
  final List<String>? specificQuestionUuids;

  /// Optional stable analytics key (e.g. `mcq_battle`) stored on the session row.
  final String? analyticsFeatureKey;

  SessionConfig copyWith({
    String? subject,
    String? topic,
    String? subTopic,
    String? mode,
    int? questionCount,
    bool? isTimed,
    int? timeLimitSecs,
    String? language,
    List<String>? specificQuestionUuids,
    String? analyticsFeatureKey,
  }) {
    return SessionConfig(
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subTopic: subTopic ?? this.subTopic,
      mode: mode ?? this.mode,
      questionCount: questionCount ?? this.questionCount,
      isTimed: isTimed ?? this.isTimed,
      timeLimitSecs: timeLimitSecs ?? this.timeLimitSecs,
      language: language ?? this.language,
      specificQuestionUuids: specificQuestionUuids ?? this.specificQuestionUuids,
      analyticsFeatureKey: analyticsFeatureKey ?? this.analyticsFeatureKey,
    );
  }
}
