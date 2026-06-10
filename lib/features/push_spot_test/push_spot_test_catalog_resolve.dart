import '../../core/constants/question_source_constants.dart';
import '../../core/constants/subject_constants.dart';
import '../../core/database/user_db.dart';

String _normalizeCatalogKey(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-—]+'), '');

/// Maps notification / debug input to the [Questions.subject] value in SQLite.
String resolvePushSpotTestSubject(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final fromConstants = SubjectConstants.bySlug(trimmed);
  if (fromConstants != null) return fromConstants.slug;
  return QuestionSourceConstants.normalizeGsSubject(trimmed);
}

/// Resolves a topic label or slug to the canonical topic string in SQLite.
Future<String?> resolvePushSpotTestTopic({
  required QuestionsDao questionsDao,
  required String subject,
  required String topicRaw,
}) async {
  final raw = topicRaw.trim();
  if (raw.isEmpty) return null;

  final rows = await questionsDao.getTopicQuestionCountsForSubject(subject);
  if (rows.isEmpty) return null;

  final topics = rows.map((r) => r.topic).toList();

  for (final t in topics) {
    if (t == raw) return t;
  }

  final lower = raw.toLowerCase();
  for (final t in topics) {
    if (t.toLowerCase() == lower) return t;
  }

  final key = _normalizeCatalogKey(raw);
  for (final t in topics) {
    if (_normalizeCatalogKey(t) == key) return t;
  }

  final tokens = raw
      .toLowerCase()
      .split(RegExp(r'[\s_\-]+'))
      .where((t) => t.length > 2)
      .toList();
  if (tokens.isNotEmpty) {
    String? best;
    var bestScore = 0;
    for (final t in topics) {
      final tl = t.toLowerCase();
      final score = tokens.where(tl.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    if (best != null && bestScore == tokens.length) return best;
  }

  return null;
}

/// Resolves subtopic input to a value present in SQLite for the subject/topic.
Future<String?> resolvePushSpotTestSubTopic({
  required QuestionsDao questionsDao,
  required String subject,
  required String topic,
  required String subTopicRaw,
}) async {
  final raw = subTopicRaw.trim();
  if (raw.isEmpty) return null;

  final subTopics = await questionsDao.getDistinctSubTopicsForSubjectTopic(
    subject,
    topic,
  );
  if (subTopics.isEmpty) return raw;

  for (final s in subTopics) {
    if (s == raw) return s;
  }
  final lower = raw.toLowerCase();
  for (final s in subTopics) {
    if (s.toLowerCase() == lower) return s;
  }
  final key = _normalizeCatalogKey(raw);
  for (final s in subTopics) {
    if (_normalizeCatalogKey(s) == key) return s;
  }
  return raw;
}
