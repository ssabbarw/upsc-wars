import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_database_provider.dart';
import '../domain/subject_scored_accuracy_summary.dart';

/// Overall scored accuracy and how often Sure / Educated-guess marks were wrong (lifetime).
final subjectScoredAccuracyProvider =
    FutureProvider.autoDispose.family<SubjectScoredAccuracySummary, String>(
  (ref, subject) async {
    final db = ref.watch(userDatabaseProvider);

    final overall = await db
        .customSelect(
          '''
          SELECT
            COUNT(*) AS total,
            COUNT(DISTINCT a.question_uuid) AS unique_count,
            COALESCE(SUM(CASE WHEN a.is_correct = 1 THEN 1 ELSE 0 END), 0) AS correct_count
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.attempted_at IS NOT NULL
            AND a.is_correct IS NOT NULL
          ''',
          variables: [Variable.withString(subject)],
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .getSingle();

    final confidenceRow = await db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' THEN 1 ELSE 0 END), 0) AS sure_total,
            COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS sure_wrong,
            COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' THEN 1 ELSE 0 END), 0) AS guess_total,
            COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS guess_wrong
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.attempted_at IS NOT NULL
            AND a.is_correct IS NOT NULL
          ''',
          variables: [Variable.withString(subject)],
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .getSingle();

    return SubjectScoredAccuracySummary(
      scoredAttempted: overall.read<int>('total'),
      scoredCorrect: overall.read<int>('correct_count'),
      uniqueQuestionsAttempted: overall.read<int>('unique_count'),
      sureTotal: confidenceRow.read<int>('sure_total'),
      sureWrong: confidenceRow.read<int>('sure_wrong'),
      educatedGuessTotal: confidenceRow.read<int>('guess_total'),
      educatedGuessWrong: confidenceRow.read<int>('guess_wrong'),
    );
  },
);
