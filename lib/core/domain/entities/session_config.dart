/// Thrown when [SessionConfig.requireAllSpecificUuids] is set and the local
/// question bank cannot supply every requested UUID.
class MissingQuestionsException implements Exception {
  const MissingQuestionsException({required this.wanted, required this.found});

  final int wanted;
  final int found;

  @override
  String toString() =>
      'MissingQuestionsException: found $found of $wanted questions locally';
}

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
    this.dangerReviseHistoryConfidence,
    this.requireAllSpecificUuids = false,
  });

  final String subject;
  final String? topic;
  final String? subTopic;

  /// 'exam' | 'learning'
  final String mode;
  final int questionCount;

  /// Exam: overall timer when [timeLimitSecs] is set. Learning: per-question
  /// countdown when true; when false, learning runs as untimed review.
  final bool isTimed;

  /// Exam: total seconds when timed; Learning: per-question limit when timed.
  final int? timeLimitSecs;
  final String language;

  /// When set, session is built from exactly these UUIDs (in order) instead of
  /// querying by subject/topic.
  final List<String>? specificQuestionUuids;

  /// Optional stable analytics key (e.g. `mcq_battle`) stored on the session row.
  final String? analyticsFeatureKey;

  /// When set with [specificQuestionUuids], after insert each new session row is
  /// filled from the learner's latest wrong attempt at this confidence so review
  /// opens with their pick and the correct answer visible.
  final String? dangerReviseHistoryConfidence;

  /// Fail instead of silently shortening the paper when the bundled question
  /// bank is missing some of [specificQuestionUuids]. Set this for scored
  /// all-India papers, where a short paper would mean an unfair rank.
  final bool requireAllSpecificUuids;

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
    String? dangerReviseHistoryConfidence,
    bool? requireAllSpecificUuids,
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
      dangerReviseHistoryConfidence:
          dangerReviseHistoryConfidence ?? this.dangerReviseHistoryConfidence,
      requireAllSpecificUuids:
          requireAllSpecificUuids ?? this.requireAllSpecificUuids,
    );
  }
}
