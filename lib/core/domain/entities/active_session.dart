import 'test_question.dart';

class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.mode,
    required this.subject,
    required this.topic,
    required this.subTopic,
    required this.questionCount,
    required this.isTimed,
    required this.timeLimitSecs,
    required this.status,
    required this.language,
    required this.questions,
    this.savedExamRemainingSecs,
    this.analyticsFeatureKey,
  });

  final String id;
  final String mode;
  final String subject;
  final String? topic;
  final String? subTopic;
  final int questionCount;
  final bool isTimed;
  final int? timeLimitSecs;
  final String status;
  final String language;
  final List<TestQuestion> questions;

  /// Persisted remaining time for timed exam resume; null if never saved.
  final int? savedExamRemainingSecs;

  /// When set, overrides subject-based analytics feature resolution.
  final String? analyticsFeatureKey;
}
