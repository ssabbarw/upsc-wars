import 'package:drift/drift.dart';

import '../../../core/database/user_db.dart';

/// Per-topic Sure / Educated-guess wrongs from tests submitted this season.
/// Keys are [Question.topic] strings.
Future<Map<String, ({int sure, int guess})>> fetchSeasonTopicDanger(
  UserDatabase db,
  String subject,
  DateTime seasonStart,
) async {
  final dangerRows = await db
      .customSelect(
        '''
        SELECT
          q.topic AS topic,
          COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' THEN 1 ELSE 0 END), 0) AS sure_w,
          COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' THEN 1 ELSE 0 END), 0) AS guess_w
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND s.status = 'completed'
          AND s.completed_at >= ?
          AND a.is_correct = 0
          AND a.confidence IN ('very_sure', 'somewhat_sure')
        GROUP BY q.topic
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000),
        ],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();
  return {
    for (final r in dangerRows)
      r.read<String>('topic'): (
        sure: r.read<int>('sure_w'),
        guess: r.read<int>('guess_w'),
      ),
  };
}

/// Per-topic counts of wrong attempts with Sure / Educated-guess (lifetime).
/// Keys are [Question.topic] strings.
Future<Map<String, ({int sure, int guess})>> fetchSubjectTopicDanger(
  UserDatabase db,
  String subject,
) async {
  final dangerRows = await db
      .customSelect(
        '''
        SELECT
          q.topic AS topic,
          COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' THEN 1 ELSE 0 END), 0) AS sure_w,
          COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' THEN 1 ELSE 0 END), 0) AS guess_w
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE q.subject = ?
          AND a.is_correct = 0
          AND a.attempted_at IS NOT NULL
          AND a.confidence IN ('very_sure', 'somewhat_sure')
        GROUP BY q.topic
        ''',
        variables: [Variable.withString(subject)],
        readsFrom: {db.sessionQuestions, db.questions},
      )
      .get();
  return {
    for (final r in dangerRows)
      r.read<String>('topic'): (
        sure: r.read<int>('sure_w'),
        guess: r.read<int>('guess_w'),
      ),
  };
}
