/// Raw metrics from question + user DB for building subject/topic lists.
class SubjectMetrics {
  const SubjectMetrics({
    required this.subjectSlug,
    required this.questionCount,
    required this.topicCount,
    required this.scoredAttemptCount,
    required this.scoredCorrectCount,
  });

  final String subjectSlug;
  final int questionCount;
  final int topicCount;
  final int scoredAttemptCount;
  final int scoredCorrectCount;
}

class TopicMetrics {
  const TopicMetrics({
    required this.topicSlug,
    required this.subjectSlug,
    required this.displayName,
    required this.questionCount,
    required this.scoredAttemptCount,
    required this.scoredCorrectCount,
  });

  final String topicSlug;
  final String subjectSlug;
  final String displayName;
  final int questionCount;
  final int scoredAttemptCount;
  final int scoredCorrectCount;
}

abstract class TestCatalogRepository {
  Future<List<SubjectMetrics>> fetchSubjectMetrics(String language);

  Future<List<TopicMetrics>> fetchTopicMetrics(
    String subjectSlug,
    String language,
  );
}
