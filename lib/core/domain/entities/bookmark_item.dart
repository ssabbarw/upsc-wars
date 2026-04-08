class BookmarkItem {
  const BookmarkItem({
    required this.id,
    required this.questionUuid,
    required this.createdAt,
    required this.note,
    required this.subjectSlug,
    required this.topicSlug,
    required this.questionStem,
  });

  final String id;
  final String questionUuid;
  final DateTime createdAt;
  final String? note;

  final String subjectSlug;
  final String topicSlug;
  final String questionStem;
}
