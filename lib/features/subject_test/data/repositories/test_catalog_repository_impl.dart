import 'package:upsc_wars/core/constants/subject_constants.dart';
import 'package:upsc_wars/core/database/question_db.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/repositories/test_catalog_repository.dart';

class TestCatalogRepositoryImpl implements TestCatalogRepository {
  TestCatalogRepositoryImpl({
    required QuestionDb questionDb,
    required UserDatabase userDatabase,
  })  : _questionDb = questionDb,
        _userDatabase = userDatabase;

  final QuestionDb _questionDb;
  final UserDatabase _userDatabase;

  @override
  Future<List<SubjectMetrics>> fetchSubjectMetrics(String language) async {
    final scored = await _userDatabase.sessionQuestionsDao.getScoredPracticeRows();
    final bySubject = await _aggregateBySubject(scored);
    final out = <SubjectMetrics>[];
    for (final def in SubjectConstants.ordered) {
      final slug = def.slug;
      final qCount = await _questionDb.getQuestionCountForSubject(slug);
      final topicCount = await _questionDb.getDistinctTopicCountForSubject(slug);
      final agg = bySubject[slug] ?? _Agg();
      out.add(
        SubjectMetrics(
          subjectSlug: slug,
          questionCount: qCount,
          topicCount: topicCount,
          scoredAttemptCount: agg.attempted,
          scoredCorrectCount: agg.correct,
        ),
      );
    }
    return out;
  }

  @override
  Future<List<TopicMetrics>> fetchTopicMetrics(
    String subjectSlug,
    String language,
  ) async {
    final scored = await _userDatabase.sessionQuestionsDao.getScoredPracticeRows();
    final byTopic = await _aggregateByTopic(scored, subjectSlug);
    final counts = await _questionDb.getQuestionCountsByTopicForSubject(subjectSlug);
    final names = await _questionDb.getTopicDisplayNamesForSubject(subjectSlug, language);
    final slugs = names.keys.toList()
      ..sort((a, b) => names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase()));
    return [
      for (final slug in slugs)
        TopicMetrics(
          topicSlug: slug,
          subjectSlug: subjectSlug,
          displayName: names[slug] ?? slug,
          questionCount: counts[slug] ?? 0,
          scoredAttemptCount: byTopic[slug]?.attempted ?? 0,
          scoredCorrectCount: byTopic[slug]?.correct ?? 0,
        ),
    ];
  }

  Future<Map<String, _Agg>> _aggregateBySubject(
    List<ScoredSessionQuestionRow> rows,
  ) async {
    if (rows.isEmpty) return {};
    final uuids = rows.map((r) => r.questionUuid).toList();
    final locs = await _questionDb.getSubjectTopicForUuids(uuids);
    final map = <String, _Agg>{};
    for (final row in rows) {
      final loc = locs[row.questionUuid];
      if (loc == null) continue;
      final a = map.putIfAbsent(loc.subjectSlug, _Agg.new);
      a.attempted++;
      if (row.isCorrect) a.correct++;
    }
    return map;
  }

  Future<Map<String, _Agg>> _aggregateByTopic(
    List<ScoredSessionQuestionRow> rows,
    String subjectSlug,
  ) async {
    if (rows.isEmpty) return {};
    final uuids = rows.map((r) => r.questionUuid).toList();
    final locs = await _questionDb.getSubjectTopicForUuids(uuids);
    final map = <String, _Agg>{};
    for (final row in rows) {
      final loc = locs[row.questionUuid];
      if (loc == null || loc.subjectSlug != subjectSlug) continue;
      final a = map.putIfAbsent(loc.topicSlug, _Agg.new);
      a.attempted++;
      if (row.isCorrect) a.correct++;
    }
    return map;
  }
}

class _Agg {
  int attempted = 0;
  int correct = 0;
}
