import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/user_db.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/practice_subject_insights.dart';
import 'practice_catalog_provider.dart';

const kPatternPracticeLimit = 10;

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

/// UUIDs of this stem pattern in [subject], confident-wrongs first.
Future<List<String>> loadPatternPracticeUuids(
  UserDatabase db, {
  required String subject,
  required SubjectMcqPatternStat pattern,
  int limit = kPatternPracticeLimit,
}) async {
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
  final ofPattern = <String>[];
  for (final row in bank) {
    final type = row.read<String>('qtype');
    final classified = classifyUpscMcqPattern(type);
    final matches =
        classified == pattern.pattern &&
        (classified != UpscMcqPattern.other ||
            _normalizeForMatch(type) == pattern.otherSlug);
    if (matches) ofPattern.add(row.read<String>('uuid'));
  }
  if (ofPattern.isEmpty) return const [];

  final wrongRows = await db
      .customSelect(
        '''
        SELECT DISTINCT a.question_uuid AS uuid
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND s.status = 'completed'
          AND a.is_correct = 0
          AND a.confidence IN ('very_sure', 'somewhat_sure')
        ''',
        variables: [Variable.withString(subject)],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();
  final wrong = {for (final r in wrongRows) r.read<String>('uuid')};

  final prioritized = [
    ...ofPattern.where(wrong.contains),
    ...ofPattern.where((id) => !wrong.contains(id)),
  ];
  return prioritized.take(limit).toList();
}

String _normalizeForMatch(String raw) =>
    raw.trim().toLowerCase().replaceAll('_', '-');
