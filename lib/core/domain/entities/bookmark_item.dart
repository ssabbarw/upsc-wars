class BookmarkItem {
  const BookmarkItem({
    required this.id,
    required this.questionUuid,
    required this.createdAt,
    required this.userNote,
    required this.subject,
    required this.topic,
    required this.questionStem,
  });

  final String id;
  final String questionUuid;
  final DateTime createdAt;
  final String? userNote;

  final String subject;
  final String topic;
  final String questionStem;
}
