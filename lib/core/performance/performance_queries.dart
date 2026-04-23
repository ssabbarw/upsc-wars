import 'package:drift/drift.dart';

import '../database/user_db.dart';
import '../domain/entities/answer_confidence.dart';

/// Per-topic attempt aggregates for a subject (scored attempts only).
class TopicRollup {
  const TopicRollup({
    required this.topic,
    required this.attempted,
    required this.correct,
    required this.sureCorrect,
    required this.sureWrong,
  });

  final String topic;
  final int attempted;
  final int correct;
  final int sureCorrect;
  final int sureWrong;
}

/// Aggregates attempts by topic for status heuristics in performance UI.
Future<List<TopicRollup>> topicRollupsForSubject(
  UserDatabase db,
  String subject,
) async {
  final rows = await db
      .customSelect(
        '''
        SELECT
          q.topic AS topic,
          COALESCE(COUNT(*), 0) AS att,
          COALESCE(SUM(CASE WHEN a.status = 'correct' THEN 1 ELSE 0 END), 0) AS cor,
          COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'correct' THEN 1 ELSE 0 END), 0) AS sc,
          COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'wrong' THEN 1 ELSE 0 END), 0) AS sw
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE q.subject = ?
          AND a.attempted_at IS NOT NULL
          AND a.status IN ('correct', 'wrong')
        GROUP BY q.topic
        ''',
        variables: [
          Variable.withString(AnswerConfidence.verySure),
          Variable.withString(AnswerConfidence.verySure),
          Variable.withString(subject),
        ],
        readsFrom: {db.sessionQuestions, db.questions},
      )
      .get();

  return [
    for (final r in rows)
      TopicRollup(
        topic: r.read<String>('topic'),
        attempted: r.read<int>('att'),
        correct: r.read<int>('cor'),
        sureCorrect: r.read<int>('sc'),
        sureWrong: r.read<int>('sw'),
      ),
  ];
}
