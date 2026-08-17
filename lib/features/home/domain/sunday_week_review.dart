import 'package:drift/drift.dart';

import '../../../core/database/user_db.dart';
import '../../../core/constants/daily_drill_constants.dart';

/// Sunday's third daily loop: re-attempt mistakes from Mon–Sat of this week.
abstract final class SundayWeekReview {
  SundayWeekReview._();

  static const analyticsKey = 'sunday_week_review';
  static const sessionSubject = 'sunday_review';
  static const questionCount = DailyDrillConstants.questionCount;

  /// Monday 00:00 of the IST week that contains [istNow].
  static DateTime weekStartMonday(DateTime istNow) {
    final day = DateTime(istNow.year, istNow.month, istNow.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// Exclusive end of that week (next Monday 00:00).
  static DateTime weekEndExclusive(DateTime istNow) =>
      weekStartMonday(istNow).add(const Duration(days: 7));

  /// Distinct wrong questions from this week, newest first, capped at [limit].
  static Future<List<String>> queryWrongUuids(
    UserDatabase db, {
    required DateTime startInclusive,
    required DateTime endExclusive,
    int limit = questionCount,
  }) async {
    final rows = await db
        .customSelect(
          '''
          SELECT a.question_uuid AS quid
          FROM attempts a
          WHERE a.is_correct = 0
            AND a.status = 'wrong'
            AND a.attempted_at IS NOT NULL
            AND a.attempted_at >= ?
            AND a.attempted_at < ?
          GROUP BY a.question_uuid
          ORDER BY MAX(a.attempted_at) DESC
          LIMIT ?
          ''',
          variables: [
            Variable.withDateTime(startInclusive),
            Variable.withDateTime(endExclusive),
            Variable.withInt(limit),
          ],
          readsFrom: {db.sessionQuestions},
        )
        .get();
    return [for (final r in rows) r.read<String>('quid')];
  }
}
