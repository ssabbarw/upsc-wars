class RevisionQueueItem {
  const RevisionQueueItem({
    required this.id,
    required this.questionUuid,
    required this.addedAt,
    required this.reason,
    required this.correctStreak,
    required this.lastCorrectAt,
    required this.subjectSlug,
    required this.topicSlug,
    required this.questionStem,
  });

  final String id;
  final String questionUuid;
  final DateTime addedAt;
  final String reason;
  final int correctStreak;
  final DateTime? lastCorrectAt;

  final String subjectSlug;
  final String topicSlug;
  final String questionStem;
}
