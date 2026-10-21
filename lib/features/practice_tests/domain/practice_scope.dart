/// A subject pool, or one topic inside a subject.
class PracticeScope {
  const PracticeScope.subject(this.subject) : topic = null;

  const PracticeScope.topic(this.subject, String this.topic);

  final String subject;
  final String? topic;

  bool get isTopic => topic != null;

  /// Stable scope segment inside a practice test id.
  String get key =>
      topic == null ? 'subject:$subject' : 'topic:$subject:$topic';

  @override
  bool operator ==(Object other) =>
      other is PracticeScope &&
      other.subject == subject &&
      other.topic == topic;

  @override
  int get hashCode => Object.hash(subject, topic);
}

class PracticeTest {
  const PracticeTest({
    required this.number,
    required this.testId,
    required this.uuids,
    this.lastCompleted,
    this.inProgressSessionId,
  });

  final int number;
  final String testId;
  final List<String> uuids;
  final PracticeCompletion? lastCompleted;
  final String? inProgressSessionId;

  int get questionCount => uuids.length;
  bool get isDone => lastCompleted != null;
}

class PracticeCompletion {
  const PracticeCompletion({
    required this.sessionId,
    required this.score,
    required this.questionCount,
    required this.completedAt,
  });

  final String sessionId;
  final int? score;
  final int questionCount;
  final DateTime? completedAt;
}

class PracticeScopeProgress {
  const PracticeScopeProgress({
    required this.testsDone,
    required this.testsTotal,
    required this.poolSize,
    required this.answered,
    required this.correct,
  });

  final int testsDone;
  final int testsTotal;
  final int poolSize;
  final int answered;
  final int correct;

  static const empty = PracticeScopeProgress(
    testsDone: 0,
    testsTotal: 0,
    poolSize: 0,
    answered: 0,
    correct: 0,
  );

  /// Share of the pool answered this season, 0–100.
  double? get coveragePercent =>
      poolSize <= 0 ? null : (answered / poolSize) * 100;

  /// Latest-answer accuracy this season, 0–100.
  double? get accuracyPercent =>
      answered <= 0 ? null : (correct / answered) * 100;
}
