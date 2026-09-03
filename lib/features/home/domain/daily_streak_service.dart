import 'package:intl/intl.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';

/// The one daily streak, fed by the first MCQ of the day (test or CA Shot).
///
/// Day boundary is IST. One missed day is grace (streak still shows); a second
/// consecutive miss zeroes it. Reuses `currentStreak` / `lastActiveDate` so
/// older streaks carry over.
abstract final class DailyStreakService {
  DailyStreakService._();

  /// Full-day history kept on device (two weeks is plenty for "this week").
  static const _maxFullDayDates = 14;

  /// Milestones worth celebrating once when first reached.
  static const celebrationMilestones = <int>[3, 7, 14, 30];

  static final _fmt = DateFormat('yyyy-MM-dd');

  static String _key(DateTime day) => _fmt.format(day);

  static DateTime _clock(DateTime? now) => now ?? DailyCaSchedule.nowIst();

  static String _yesterdayKey(DateTime today) =>
      _key(today.subtract(const Duration(days: 1)));

  static String _dayBeforeYesterdayKey(DateTime today) =>
      _key(today.subtract(const Duration(days: 2)));

  /// Records a closed ring for [now] and returns the resulting streak.
  ///
  /// Safe to call repeatedly — the first close of the day is what counts.
  /// One idle day between closes still extends the streak (grace).
  static int recordRingClosed({required PrefsService prefs, DateTime? now}) {
    final today = _clock(now);
    final todayKey = _key(today);
    if (prefs.lastActiveDate == todayKey) {
      if (prefs.currentStreak > 0) return prefs.currentStreak;
      prefs.currentStreak = 1;
      if (prefs.longestStreak < 1) prefs.longestStreak = 1;
      _queueMilestoneIfNeeded(prefs, 1);
      return 1;
    }

    final last = prefs.lastActiveDate;
    final next = (last == _yesterdayKey(today) ||
            last == _dayBeforeYesterdayKey(today))
        ? (prefs.currentStreak == 0 ? 1 : prefs.currentStreak + 1)
        : 1;

    prefs.currentStreak = next;
    prefs.lastActiveDate = todayKey;
    if (next > prefs.longestStreak) prefs.longestStreak = next;
    _queueMilestoneIfNeeded(prefs, next);
    return next;
  }

  /// The streak as it should be shown — still alive through one grace day.
  ///
  /// Stored streaks go stale after two idle days, so a user who stopped a week
  /// ago must not still see their old number.
  static int visibleStreak({required PrefsService prefs, DateTime? now}) {
    final today = _clock(now);
    final last = prefs.lastActiveDate;
    if (last == null || last.isEmpty) return 0;
    if (last == _key(today) ||
        last == _yesterdayKey(today) ||
        last == _dayBeforeYesterdayKey(today)) {
      return prefs.currentStreak;
    }
    return 0;
  }

  /// Whether today has already fed the streak.
  static bool closedToday({required PrefsService prefs, DateTime? now}) =>
      prefs.lastActiveDate == _key(_clock(now));

  /// Whole days from [now]'s calendar day until the evening the streak dies.
  ///
  /// Null when there is no meaningful streak to protect (`< 2`). Used by the
  /// drill reminder window so "ends tonight" only fires on the grace-expiry
  /// night — not on the first idle evening.
  static int? daysUntilStreakExpires({
    required PrefsService prefs,
    DateTime? now,
  }) {
    if (visibleStreak(prefs: prefs, now: now) < 2) return null;
    final today = _clock(now);
    final last = prefs.lastActiveDate;
    if (last == null || last.isEmpty) return null;
    if (last == _key(today)) return 2;
    if (last == _yesterdayKey(today)) return 1;
    if (last == _dayBeforeYesterdayKey(today)) return 0;
    return null;
  }

  /// Marks [now] as a day where every available ring was closed. Idempotent.
  static void recordFullDay({required PrefsService prefs, DateTime? now}) {
    final todayKey = _key(_clock(now));
    final dates = prefs.todayFullDayDates;
    if (dates.contains(todayKey)) return;
    final next = [...dates, todayKey];
    if (next.length > _maxFullDayDates) {
      next.removeRange(0, next.length - _maxFullDayDates);
    }
    prefs.todayFullDayDates = next;
  }

  /// Full days within the last 7 calendar days, including today.
  static int fullDaysThisWeek({required PrefsService prefs, DateTime? now}) {
    final today = _clock(now);
    final keys = <String>{
      for (var i = 0; i < 7; i++)
        _key(today.subtract(Duration(days: i))),
    };
    return prefs.todayFullDayDates.where(keys.contains).length;
  }

  /// Pending milestone toast for Home, or null.
  static int? consumePendingMilestoneCelebration(PrefsService prefs) {
    final pending = prefs.pendingStreakMilestoneCelebration;
    if (pending == null) return null;
    prefs.pendingStreakMilestoneCelebration = null;
    return pending;
  }

  static void _queueMilestoneIfNeeded(PrefsService prefs, int streak) {
    if (!celebrationMilestones.contains(streak)) return;
    final celebrated = prefs.celebratedStreakMilestones;
    if (celebrated.contains(streak)) return;
    prefs.celebratedStreakMilestones = {...celebrated, streak};
    prefs.pendingStreakMilestoneCelebration = streak;
  }
}
