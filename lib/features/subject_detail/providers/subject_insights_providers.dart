import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_database_provider.dart';
import '../domain/subject_insights.dart';

/// Insight data for a single subject.
/// Invalidate this provider after a session completes to refresh counts.
final subjectInsightsProvider = FutureProvider.autoDispose
    .family<SubjectInsights, String>((ref, subject) async {
      final db = ref.watch(userDatabaseProvider);

      final splitRow = await db
          .customSelect(
            '''
          SELECT
            COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' THEN 1 ELSE 0 END), 0) AS sure_w,
            COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' THEN 1 ELSE 0 END), 0) AS guess_w
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.is_correct = 0
            AND a.attempted_at IS NOT NULL
            AND a.confidence IN ('very_sure', 'somewhat_sure')
          ''',
            variables: [Variable.withString(subject)],
            readsFrom: {db.sessionQuestions, db.questions},
          )
          .getSingle();
      final sureWrong = splitRow.read<int>('sure_w');
      final guessWrong = splitRow.read<int>('guess_w');
      final dangerTotal = sureWrong + guessWrong;
      final marks = dangerTotal * 0.66;

      final topicRows = await db
          .customSelect(
            '''
          SELECT q.topic AS topic, COUNT(*) AS danger_count
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.is_correct = 0
            AND a.attempted_at IS NOT NULL
            AND a.confidence IN ('very_sure', 'somewhat_sure')
          GROUP BY q.topic
          ORDER BY danger_count DESC
          ''',
            variables: [Variable.withString(subject)],
            readsFrom: {db.sessionQuestions, db.questions},
          )
          .get();

      final raw = topicRows
          .map(
            (row) => (
              topic: row.read<String>('topic'),
              dangerCount: row.read<int>('danger_count'),
            ),
          )
          .toList();

      final tiered = topicRowsWithPercentileTiers(raw);

      return SubjectInsights(
        dangerZoneWrongCount: dangerTotal,
        dangerZoneSureWrongCount: sureWrong,
        dangerZoneEducatedGuessWrongCount: guessWrong,
        dangerZoneMarks: marks,
        topicPercentiles: tiered,
      );
    });
