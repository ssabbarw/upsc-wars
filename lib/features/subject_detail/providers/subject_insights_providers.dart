import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_database_provider.dart';
import '../domain/subject_insights.dart';

/// Insight data for a single subject.
/// Invalidate this provider after a session completes to refresh counts.
final subjectInsightsProvider =
    FutureProvider.autoDispose.family<SubjectInsights, String>(
  (ref, subject) async {
    final db = ref.watch(userDatabaseProvider);
    final since = DateTime.now().subtract(const Duration(days: 30));

    final dangerTotalRow = await db
        .customSelect(
          '''
          SELECT COUNT(*) AS c
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.is_correct = 0
            AND a.attempted_at IS NOT NULL
            AND a.attempted_at >= ?
            AND a.confidence IN ('very_sure', 'somewhat_sure')
          ''',
          variables: [
            Variable.withString(subject),
            Variable.withDateTime(since),
          ],
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .getSingle();
    final dangerTotal = dangerTotalRow.read<int>('c');
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
            AND a.attempted_at >= ?
            AND a.confidence IN ('very_sure', 'somewhat_sure')
          GROUP BY q.topic
          ORDER BY danger_count DESC
          ''',
          variables: [
            Variable.withString(subject),
            Variable.withDateTime(since),
          ],
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
      dangerZoneCountLast30Days: dangerTotal,
      dangerZoneMarksLast30: marks,
      topicPercentiles: tiered,
    );
  },
);
