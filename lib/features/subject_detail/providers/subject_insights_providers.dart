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

    // ── 1. Wrong answer count for this subject, last 30 days ─────────────
    final wrongCountRow = await db
        .customSelect(
          '''
          SELECT COUNT(*) AS c
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.is_correct = 0
            AND a.attempted_at IS NOT NULL
            AND a.attempted_at >= ?
          ''',
          variables: [
            Variable.withString(subject),
            Variable.withDateTime(since),
          ],
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .getSingle();
    final wrongCount = wrongCountRow.read<int>('c');

    // ── 2. Topic risk ranking (all-time via cached UserTopicStats) ────────
    // Sorted by wrongAttempts desc; only topics with at least 1 wrong answer.
    final topicStats = await db.userTopicStatsDao.fetchBySubject(subject);
    final topicRisks = (topicStats.toList()
          ..sort((a, b) => b.wrongAttempts.compareTo(a.wrongAttempts)))
        .where((t) => t.wrongAttempts > 0)
        .take(5)
        .toList();

    // ── 3. Trap blind spots — grouped by trap_type (min 2 attempts) ───────
    final trapRows = await db
        .customSelect(
          '''
          SELECT
            q.trap_type,
            COUNT(*) AS total_attempts,
            SUM(CASE WHEN a.is_correct = 0 THEN 1 ELSE 0 END) AS wrong_count
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND q.trap_type IS NOT NULL
            AND a.is_correct IS NOT NULL
          GROUP BY q.trap_type
          HAVING total_attempts >= 2
          ORDER BY wrong_count DESC
          ''',
          variables: [Variable.withString(subject)],
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .get();

    final trapBlindSpots = trapRows
        .map(
          (row) => TrapBlindSpotRow(
            trapType: row.read<String>('trap_type'),
            totalAttempts: row.read<int>('total_attempts'),
            wrongCount: row.read<int>('wrong_count'),
          ),
        )
        .take(5)
        .toList();

    return SubjectInsights(
      wrongCountLast30Days: wrongCount,
      topicRisks: topicRisks,
      trapBlindSpots: trapBlindSpots,
    );
  },
);
