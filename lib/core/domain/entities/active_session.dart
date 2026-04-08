import 'test_question.dart';

class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.mode,
    required this.subjectSlug,
    required this.topicSlug,
    required this.subTopicSlug,
    required this.questionCount,
    required this.isTimed,
    required this.timeLimitSecs,
    required this.status,
    required this.language,
    required this.questions,
    this.savedExamRemainingSecs,
  });

  final String id;
  final String mode;
  final String subjectSlug;
  final String? topicSlug;
  final String? subTopicSlug;
  final int questionCount;
  final bool isTimed;
  final int? timeLimitSecs;
  final String status;
  final String language;
  final List<TestQuestion> questions;

  /// Persisted remaining time for timed exam resume; null if never saved.
  final int? savedExamRemainingSecs;
}
