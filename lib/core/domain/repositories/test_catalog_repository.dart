/// Raw metrics from question + user DB for building subject/topic lists.
class SubjectMetrics {
  const SubjectMetrics({
    required this.subject,
    required this.questionCount,
    required this.topicCount,
    required this.scoredAttemptCount,
    required this.scoredCorrectCount,
  });

  final String subject;
  final int questionCount;
  final int topicCount;
  final int scoredAttemptCount;
  final int scoredCorrectCount;
}

class TopicMetrics {
  const TopicMetrics({
    required this.topic,
    required this.subject,
    required this.displayName,
    required this.questionCount,
    required this.scoredAttemptCount,
    required this.scoredCorrectCount,
  });

  final String topic;
  final String subject;
  final String displayName;
  final int questionCount;
  final int scoredAttemptCount;
  final int scoredCorrectCount;
}

abstract class TestCatalogRepository {
  Future<List<SubjectMetrics>> fetchSubjectMetrics(String language);

  Future<List<TopicMetrics>> fetchTopicMetrics(String subject, String language);
}
