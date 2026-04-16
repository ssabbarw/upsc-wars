class RevisionQueueItem {
  const RevisionQueueItem({
    required this.id,
    required this.questionUuid,
    required this.dateAddedToQueue,
    required this.numberOfTimesAnsweredCorrectlyInRevision,
    required this.numberOfTimesAnsweredIncorrectlyInRevision,
    required this.hasGraduatedFromQueue,
    required this.dateGraduated,
    required this.subject,
    required this.topic,
    required this.questionStem,
  });

  final String id;
  final String questionUuid;
  final DateTime dateAddedToQueue;
  final int numberOfTimesAnsweredCorrectlyInRevision;
  final int numberOfTimesAnsweredIncorrectlyInRevision;
  final bool hasGraduatedFromQueue;
  final DateTime? dateGraduated;

  final String subject;
  final String topic;
  final String questionStem;
}
