import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_database_provider.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../domain/sunday_week_review.dart';
import 'daily_drill_provider.dart';
import 'home_activation_provider.dart';

class SundayWeekReviewState {
  const SundayWeekReviewState({
    required this.uuids,
    required this.completedToday,
  });

  final List<String> uuids;
  final bool completedToday;

  bool get hasMistakes => uuids.isNotEmpty;
}

/// Sunday-only: mistakes from Mon–Sat of this week, ready to re-attempt.
final sundayWeekReviewProvider =
    FutureProvider.autoDispose<SundayWeekReviewState?>((ref) async {
  final activation = await ref.watch(homeActivationProvider.future);
  if (!activation.activationComplete) return null;

  final ist = DailyWarSchedule.nowIst();
  if (!DailyWarSchedule.isSunday(ist)) return null;

  final db = ref.watch(userDatabaseProvider);
  final start = SundayWeekReview.weekStartMonday(ist);
  final end = SundayWeekReview.weekEndExclusive(ist);
  final dayStart = localDayStart(DateTime.now());

  final uuids = await SundayWeekReview.queryWrongUuids(
    db,
    startInclusive: start,
    endExclusive: end,
  );
  final completedToday =
      await db.sessionsDao.hasCompletedSundayWeekReviewBetween(
    startInclusive: dayStart,
    endExclusive: dayStart.add(const Duration(days: 1)),
  );

  return SundayWeekReviewState(
    uuids: uuids,
    completedToday: completedToday,
  );
});
