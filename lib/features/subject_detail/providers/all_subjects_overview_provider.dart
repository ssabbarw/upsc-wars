import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/subject_overview_row.dart';

/// How subjects are sorted in the Progress overview screen.
enum SubjectSortMode { mistakes, accuracy, alphabetical }


/// Aggregated performance data for all 8 subjects in a single round-trip.
///
/// Returns rows in [SubjectConstants.ordered] order; sorting is applied in the
/// UI layer so it reacts instantly to [subjectSortModeProvider] changes without
/// re-querying the DB.
final allSubjectsOverviewProvider =
    FutureProvider.autoDispose<List<SubjectOverviewRow>>((ref) async {
  final db = ref.watch(userDatabaseProvider);

  // ── 1. Wrong count per subject (all-time) ─────────────────────────────────
  final wrongRows = await db
      .customSelect(
        '''
        SELECT q.subject, COUNT(*) AS wrong_count
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE a.is_correct = 0
          AND a.attempted_at IS NOT NULL
        GROUP BY q.subject
        ''',
        variables: [],
        readsFrom: {db.sessionQuestions, db.questions},
      )
      .get();

  // ── 2. All-time totals per subject ────────────────────────────────────────
  final totalRows = await db
      .customSelect(
        '''
        SELECT
          q.subject,
          COUNT(*) AS total,
          SUM(CASE WHEN a.is_correct = 1 THEN 1 ELSE 0 END) AS correct_count
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE a.is_correct IS NOT NULL
        GROUP BY q.subject
        ''',
        variables: [],
        readsFrom: {db.sessionQuestions, db.questions},
      )
      .get();

  // ── Build lookup maps ─────────────────────────────────────────────────────
  final wrongBySubject = {
    for (final r in wrongRows)
      r.read<String>('subject'): r.read<int>('wrong_count'),
  };
  final totalBySubject = {
    for (final r in totalRows)
      r.read<String>('subject'): r.read<int>('total'),
  };
  final correctBySubject = {
    for (final r in totalRows)
      r.read<String>('subject'): r.read<int>('correct_count'),
  };

  // ── Merge with SubjectConstants for display metadata ──────────────────────
  return SubjectConstants.ordered.map((def) {
    return SubjectOverviewRow(
      subject: def.slug,
      displayName: def.displayName,
      icon: def.materialIcon,
      wrongAnswerCount: wrongBySubject[def.slug] ?? 0,
      totalAttempted: totalBySubject[def.slug] ?? 0,
      totalCorrect: correctBySubject[def.slug] ?? 0,
    );
  }).toList();
});
