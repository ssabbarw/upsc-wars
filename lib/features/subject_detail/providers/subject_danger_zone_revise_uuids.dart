import 'package:drift/drift.dart';

import '../../../core/database/user_db.dart';

/// One row per question: wrong, in window, with the given confidence.
/// Ordered by most recent attempt.
Future<List<String>> querySubjectDangerZoneReviseUuids(
  UserDatabase db, {
  required String subject,
  required String confidence,
  required DateTime since,
}) async {
  final rows = await db
      .customSelect(
        '''
        SELECT a.question_uuid AS quid
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE q.subject = ?
          AND a.is_correct = 0
          AND a.attempted_at IS NOT NULL
          AND a.attempted_at >= ?
          AND a.confidence = ?
        GROUP BY a.question_uuid
        ORDER BY MAX(a.attempted_at) DESC
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withDateTime(since),
          Variable.withString(confidence),
        ],
        readsFrom: {db.sessionQuestions, db.questions},
      )
      .get();
  return [for (final r in rows) r.read<String>('quid')];
}

/// Same as [querySubjectDangerZoneReviseUuids] but limited to [topic] (catalog topic key).
Future<List<String>> queryTopicDangerZoneReviseUuids(
  UserDatabase db, {
  required String subject,
  required String topic,
  required String confidence,
  required DateTime since,
}) async {
  final rows = await db
      .customSelect(
        '''
        SELECT a.question_uuid AS quid
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE q.subject = ?
          AND q.topic = ?
          AND a.is_correct = 0
          AND a.attempted_at IS NOT NULL
          AND a.attempted_at >= ?
          AND a.confidence = ?
        GROUP BY a.question_uuid
        ORDER BY MAX(a.attempted_at) DESC
        ''',
        variables: [
          Variable.withString(subject),
          Variable.withString(topic),
          Variable.withDateTime(since),
          Variable.withString(confidence),
        ],
        readsFrom: {db.sessionQuestions, db.questions},
      )
      .get();
  return [for (final r in rows) r.read<String>('quid')];
}
