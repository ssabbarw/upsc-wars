import 'package:upsc_wars/core/constants/subject_constants.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/repositories/test_catalog_repository.dart';

class TestCatalogRepositoryImpl implements TestCatalogRepository {
  TestCatalogRepositoryImpl({required UserDatabase userDatabase})
    : _userDatabase = userDatabase;

  final UserDatabase _userDatabase;

  @override
  Future<List<SubjectMetrics>> fetchSubjectMetrics(String language) async {
    final scored = await _userDatabase.sessionQuestionsDao
        .getScoredPracticeRows();
    final bySubject = await _aggregateBySubject(scored);
    final out = <SubjectMetrics>[];
    for (final def in SubjectConstants.ordered) {
      final subject = def.slug;
      final qCount = (await _userDatabase.questionsDao.getBySubject(
        subject,
      )).length;
      final topicCount =
          (await _userDatabase.questionsDao.getTopicQuestionCountsForSubject(
            subject,
          )).length;
      final agg = bySubject[subject] ?? _Agg();
      out.add(
        SubjectMetrics(
          subject: subject,
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
    String subject,
    String language,
  ) async {
    final scored = await _userDatabase.sessionQuestionsDao
        .getScoredPracticeRows();
    final byTopic = await _aggregateByTopic(scored, subject);
    final countsRows = await _userDatabase.questionsDao
        .getTopicQuestionCountsForSubject(subject);
    final counts = {for (final row in countsRows) row.topic: row.questionCount};
    final topicNames = counts.keys.toList();
    final names = <String, String>{};
    for (final topic in topicNames) {
      if (language == 'hi') {
        final translation = await _userDatabase.topicTranslationsDao
            .getByEnglishName(topic);
        names[topic] = translation?.hindiName ?? topic;
      } else {
        names[topic] = topic;
      }
    }
    final topics = names.keys.toList()
      ..sort(
        (a, b) => names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase()),
      );
    return [
      for (final topic in topics)
        TopicMetrics(
          topic: topic,
          subject: subject,
          displayName: names[topic] ?? topic,
          questionCount: counts[topic] ?? 0,
          scoredAttemptCount: byTopic[topic]?.attempted ?? 0,
          scoredCorrectCount: byTopic[topic]?.correct ?? 0,
        ),
    ];
  }

  Future<Map<String, _Agg>> _aggregateBySubject(
    List<ScoredSessionQuestionRow> rows,
  ) async {
    if (rows.isEmpty) return {};
    final uuids = rows.map((r) => r.questionUuid).toList();
    final locs = await _userDatabase.questionsDao.getSubjectTopicForUuids(
      uuids,
    );
    final map = <String, _Agg>{};
    for (final row in rows) {
      final loc = locs[row.questionUuid];
      if (loc == null) continue;
      final a = map.putIfAbsent(loc.subject, _Agg.new);
      a.attempted++;
      if (row.isCorrect) a.correct++;
    }
    return map;
  }

  Future<Map<String, _Agg>> _aggregateByTopic(
    List<ScoredSessionQuestionRow> rows,
    String subject,
  ) async {
    if (rows.isEmpty) return {};
    final uuids = rows.map((r) => r.questionUuid).toList();
    final locs = await _userDatabase.questionsDao.getSubjectTopicForUuids(
      uuids,
    );
    final map = <String, _Agg>{};
    for (final row in rows) {
      final loc = locs[row.questionUuid];
      if (loc == null || loc.subject != subject) continue;
      final a = map.putIfAbsent(loc.topic, _Agg.new);
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
