import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
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
    .family<PracticeSubjectInsights, String>((ref, subject) {
      return _loadInsights(ref, subject: subject);
    });

/// Season insights rolled up across every subject.
///
/// Sure and Educated-guess totals, traps, and the subject lists all use the
/// same season. Subject rows are ordered by most mistakes.
final practiceAllSubjectsInsightsProvider =
    FutureProvider.autoDispose<PracticeSubjectInsights>((ref) async {
      final catalog = await ref.watch(practiceCatalogProvider.future);
      final db = ref.watch(userDatabaseProvider);
      return loadPracticeAllSubjectsInsights(
        db,
        seasonStart: catalog.season.start,
        displayNames: {
          for (final def in SubjectConstants.ordered) def.slug: def.displayName,
        },
      );
    });

/// Season insights for one topic inside a subject.
final practiceTopicInsightsProvider = FutureProvider.autoDispose
    .family<PracticeSubjectInsights, ({String subject, String topic})>((
      ref,
      args,
    ) {
      return _loadInsights(ref, subject: args.subject, topic: args.topic);
    });

Future<PracticeSubjectInsights> _loadInsights(
  Ref ref, {
  required String subject,
  String? topic,
}) async {
  final catalog = await ref.watch(practiceCatalogProvider.future);
  final db = ref.watch(userDatabaseProvider);
  return loadPracticeSubjectInsights(
    db,
    subject: subject,
    topic: topic,
    seasonStart: catalog.season.start,
    displayNames: catalog.topicDisplayNames,
  );
}

Future<PracticeSubjectInsights> loadPracticeAllSubjectsInsights(
  UserDatabase db, {
  required DateTime seasonStart,
  required Map<String, String> displayNames,
}) async {
  final insights = await _loadPracticeInsights(
    db,
    seasonStart: seasonStart,
    displayNames: displayNames,
    groupBySubject: true,
    sureMinTopic: 1,
    guessMinTopic: 1,
  );
  return insights.rankedByMostMistakes();
}

Future<PracticeSubjectInsights> loadPracticeSubjectInsights(
  UserDatabase db, {
  required String subject,
  String? topic,
  required DateTime seasonStart,
  required Map<String, String> displayNames,
}) {
  return _loadPracticeInsights(
    db,
    subject: subject,
    topic: topic,
    seasonStart: seasonStart,
    displayNames: displayNames,
    sureMinTopic: topic == null ? PracticeInsightRules.sureMinTopic : 1,
    guessMinTopic: topic == null ? PracticeInsightRules.guessMinTopic : 1,
  );
}

Future<PracticeSubjectInsights> _loadPracticeInsights(
  UserDatabase db, {
  String? subject,
  String? topic,
  bool groupBySubject = false,
  required DateTime seasonStart,
  required Map<String, String> displayNames,
  required int sureMinTopic,
  required int guessMinTopic,
}) async {
  final subjectFilter = subject == null ? '' : 'AND q.subject = ?';
  final topicFilter = topic == null ? '' : 'AND q.topic = ?';
  final groupExpr = groupBySubject ? 'q.subject' : 'q.topic';
  final scopeVars = [
    if (subject != null) Variable.withString(subject),
    if (topic != null) Variable.withString(topic),
    Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000),
  ];
  final rows = await db
      .customSelect(
        '''
        SELECT
          $groupExpr AS topic,
          COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS sure_w,
          COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' AND a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS sure_c,
          COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS guess_w,
          COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS guess_c,
          COALESCE(SUM(CASE WHEN a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS all_w,
          COALESCE(SUM(CASE WHEN a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS all_c
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE s.status = 'completed'
          $subjectFilter
          $topicFilter
          AND s.completed_at >= ?
          AND a.status IN ('correct', 'wrong')
        GROUP BY $groupExpr
        ''',
        variables: scopeVars,
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

  final trapRows = await db
      .customSelect(
        '''
        SELECT
          LOWER(REPLACE(q.trap_type, '_', '-')) AS ttype,
          a.confidence AS conf,
          COUNT(DISTINCT CASE WHEN a.is_correct = 0 THEN a.question_uuid END)
            AS wrongs,
          COUNT(DISTINCT a.question_uuid) AS tot
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE s.status = 'completed'
          $subjectFilter
          $topicFilter
          AND s.completed_at >= ?
          AND a.status IN ('correct', 'wrong')
          AND a.confidence IN ('very_sure', 'somewhat_sure')
          AND q.trap_type IS NOT NULL
          AND TRIM(q.trap_type) != ''
        GROUP BY ttype, a.confidence
        ''',
        variables: scopeVars,
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();

  List<({String type, int wrong, int attempted})> ofConf(String conf) {
    return [
      for (final r in trapRows)
        if (r.read<String>('conf') == conf)
          (
            type: r.read<String>('ttype'),
            wrong: r.read<int>('wrongs'),
            attempted: r.read<int>('tot'),
          ),
    ];
  }

  return assemblePracticeSubjectInsights(
    topics: topics,
    displayNames: displayNames,
    sureTraps: rankContentTraps(ofConf('very_sure')),
    guessTraps: rankContentTraps(ofConf('somewhat_sure')),
    sureMinTopic: sureMinTopic,
    guessMinTopic: guessMinTopic,
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
        variables: [Variable.withString(subject), Variable.withString(topic)],
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
  String? subject,
  String? topic,
  required String trapType,
  required DateTime seasonStart,
  int improveLimit = kInsightImproveSize,
}) async {
  final ofTrap = await _trapUuids(db, trapType, subject: subject, topic: topic);
  if (ofTrap.isEmpty) {
    return const InsightDrillPool(reviseUuids: [], improveUuids: []);
  }
  final season = Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000);
  final subjectFilter = subject == null ? '' : 'AND q.subject = ?';
  final topicFilter = topic == null ? '' : 'AND q.topic = ?';
  final wrongRows = await db
      .customSelect(
        '''
        SELECT a.question_uuid AS uuid
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE s.status = 'completed'
          $subjectFilter
          $topicFilter
          AND s.completed_at >= ?
          AND a.is_correct = 0
          AND a.confidence = 'very_sure'
        GROUP BY a.question_uuid
        ORDER BY MAX(a.attempted_at) DESC
        ''',
        variables: [
          if (subject != null) Variable.withString(subject),
          if (topic != null) Variable.withString(topic),
          season,
        ],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();
  final revise = [
    for (final r in wrongRows)
      if (ofTrap.contains(r.read<String>('uuid'))) r.read<String>('uuid'),
  ];
  final attempted = await _attemptedUuids(db);
  final unused = ofTrap.difference(attempted).toList()..shuffle();
  return InsightDrillPool(
    reviseUuids: revise,
    improveUuids: unused.take(improveLimit).toList(),
  );
}

Future<Set<String>> _attemptedUuids(UserDatabase db) =>
    db.sessionQuestionsDao.getAllAttemptedQuestionUuids();

Future<Set<String>> _trapUuids(
  UserDatabase db,
  String trapType, {
  String? subject,
  String? topic,
}) async {
  final want = normalizeTrapType(trapType);
  if (want.isEmpty) return {};
  final subjectFilter = subject == null ? '' : 'AND subject = ?';
  final topicFilter = topic == null ? '' : 'AND topic = ?';
  final bank = await db
      .customSelect(
        '''
        SELECT uuid, trap_type AS ttype
        FROM questions
        WHERE 1 = 1
          $subjectFilter
          $topicFilter
        ''',
        variables: [
          if (subject != null) Variable.withString(subject),
          if (topic != null) Variable.withString(topic),
        ],
        readsFrom: {db.questions},
      )
      .get();
  return {
    for (final row in bank)
      if (normalizeTrapType(row.read<String?>('ttype') ?? '') == want)
        row.read<String>('uuid'),
  };
}
