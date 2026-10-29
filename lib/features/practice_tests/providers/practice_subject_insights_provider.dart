import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/user_db.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/practice_subject_insights.dart';
import 'practice_catalog_provider.dart';

/// Full Improve set size. Below this, the sheet offers a short test or Revise.
const kInsightImproveSize = 10;

/// Wrong + new question UUIDs for a topic or trap drill.
class InsightDrillPool {
  const InsightDrillPool({
    required this.reviseUuids,
    required this.improveUuids,
  });

  final List<String> reviseUuids;
  final List<String> improveUuids;
}

/// Season confident-mistakes and attempt-more topics for one subject.
final practiceSubjectInsightsProvider = FutureProvider.autoDispose
    .family<PracticeSubjectInsights, String>((ref, subject) async {
      final catalog = await ref.watch(practiceCatalogProvider.future);
      final db = ref.watch(userDatabaseProvider);
      return loadPracticeSubjectInsights(
        db,
        subject: subject,
        seasonStart: catalog.season.start,
        displayNames: catalog.topicDisplayNames,
      );
    });

Future<PracticeSubjectInsights> loadPracticeSubjectInsights(
  UserDatabase db, {
  required String subject,
  required DateTime seasonStart,
  required Map<String, String> displayNames,
}) async {
  final rows = await db
      .customSelect(
        '''
        SELECT
          q.topic AS topic,
          COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS sure_w,
          COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' AND a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS sure_c,
          COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS guess_w,
          COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS guess_c,
          COALESCE(SUM(CASE WHEN a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS all_w,
          COALESCE(SUM(CASE WHEN a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS all_c
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND s.status = 'completed'
          AND s.completed_at >= ?
          AND a.status IN ('correct', 'wrong')
        GROUP BY q.topic
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000),
        ],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();

  final topics = <PracticeTopicRollup>[];
  for (final row in rows) {
    final topic = (row.read<String?>('topic') ?? '').trim();
    if (topic.isEmpty) continue;
    topics.add(
      PracticeTopicRollup(
        topic: topic,
        sureWrong: row.read<int>('sure_w'),
        sureCorrect: row.read<int>('sure_c'),
        educatedGuessWrong: row.read<int>('guess_w'),
        educatedGuessCorrect: row.read<int>('guess_c'),
        allWrong: row.read<int>('all_w'),
        allCorrect: row.read<int>('all_c'),
      ),
    );
  }

  final patternRows = await db
      .customSelect(
        '''
        SELECT
          q.question_type AS qtype,
          a.confidence AS conf,
          COALESCE(SUM(CASE WHEN a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS wrongs,
          COALESCE(COUNT(*), 0) AS tot
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND s.status = 'completed'
          AND s.completed_at >= ?
          AND a.status IN ('correct', 'wrong')
          AND a.confidence IN ('very_sure', 'somewhat_sure')
        GROUP BY q.question_type, a.confidence
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000),
        ],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();

  List<({String type, int wrong, int attempted})> ofConf(String conf) {
    return [
      for (final r in patternRows)
        if (r.read<String>('conf') == conf)
          (
            type: r.read<String>('qtype'),
            wrong: r.read<int>('wrongs'),
            attempted: r.read<int>('tot'),
          ),
    ];
  }

  return assemblePracticeSubjectInsights(
    topics: topics,
    displayNames: displayNames,
    surePatterns: rankMcqPatterns(ofConf('very_sure')),
    guessPatterns: rankMcqPatterns(ofConf('somewhat_sure')),
  );
}

Future<InsightDrillPool> loadTopicDrillPool(
  UserDatabase db, {
  required String subject,
  required String topic,
  required bool sureLens,
  required DateTime seasonStart,
  int improveLimit = kInsightImproveSize,
}) async {
  final confidence = sureLens ? 'very_sure' : 'somewhat_sure';
  final season = Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000);
  final wrongRows = await db
      .customSelect(
        '''
        SELECT a.question_uuid AS uuid
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND q.topic = ?
          AND s.status = 'completed'
          AND s.completed_at >= ?
          AND a.is_correct = 0
          AND a.confidence = ?
        GROUP BY a.question_uuid
        ORDER BY MAX(a.attempted_at) DESC
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withString(topic),
          season,
          Variable.withString(confidence),
        ],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();
  final attempted = await _attemptedUuids(db);
  final newRows = await db
      .customSelect(
        '''
        SELECT uuid
        FROM questions
        WHERE subject = ?
          AND topic = ?
        ORDER BY RANDOM()
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withString(topic),
        ],
        readsFrom: {db.questions},
      )
      .get();
  final improve = <String>[];
  for (final row in newRows) {
    final id = row.read<String>('uuid');
    if (attempted.contains(id)) continue;
    improve.add(id);
    if (improve.length >= improveLimit) break;
  }
  return InsightDrillPool(
    reviseUuids: [for (final r in wrongRows) r.read<String>('uuid')],
    improveUuids: improve,
  );
}

Future<InsightDrillPool> loadTrapDrillPool(
  UserDatabase db, {
  required String subject,
  required SubjectMcqPatternStat pattern,
  required DateTime seasonStart,
  int improveLimit = kInsightImproveSize,
}) async {
  final ofPattern = await _patternUuids(db, subject, pattern);
  if (ofPattern.isEmpty) {
    return const InsightDrillPool(reviseUuids: [], improveUuids: []);
  }
  final season = Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000);
  final wrongRows = await db
      .customSelect(
        '''
        SELECT a.question_uuid AS uuid
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND s.status = 'completed'
          AND s.completed_at >= ?
          AND a.is_correct = 0
          AND a.confidence = 'very_sure'
        GROUP BY a.question_uuid
        ORDER BY MAX(a.attempted_at) DESC
        ''',
        variables: [Variable.withString(subject), season],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();
  final revise = [
    for (final r in wrongRows)
      if (ofPattern.contains(r.read<String>('uuid'))) r.read<String>('uuid'),
  ];
  final attempted = await _attemptedUuids(db);
  final unused = ofPattern.difference(attempted).toList()..shuffle();
  return InsightDrillPool(
    reviseUuids: revise,
    improveUuids: unused.take(improveLimit).toList(),
  );
}

Future<Set<String>> _attemptedUuids(UserDatabase db) =>
    db.sessionQuestionsDao.getAllAttemptedQuestionUuids();

Future<Set<String>> _patternUuids(
  UserDatabase db,
  String subject,
  SubjectMcqPatternStat pattern,
) async {
  final bank = await db
      .customSelect(
        '''
        SELECT uuid, question_type AS qtype
        FROM questions
        WHERE subject = ?
        ''',
        variables: [Variable.withString(subject)],
        readsFrom: {db.questions},
      )
      .get();
  return {
    for (final row in bank)
      if (matchesMcqPattern(row.read<String>('qtype'), pattern))
        row.read<String>('uuid'),
  };
}
