import 'package:intl/intl.dart';

import '../../../core/providers/prefs_provider.dart';

/// The one daily streak, fed by closing **any** Today ring.
///
/// Reuses the existing `currentStreak` / `lastActiveDate` prefs so streaks
/// earned under the old app-open rule carry over untouched. The difference is
/// the trigger: opening the app no longer counts, finishing a paper quiz,
/// static drill, or War does.
abstract final class DailyStreakService {
  DailyStreakService._();

  /// Full-day history kept on device (two weeks is plenty for "this week").
  static const _maxFullDayDates = 14;

  static final _fmt = DateFormat('yyyy-MM-dd');

  static String _key(DateTime day) => _fmt.format(day);

  /// Records a closed ring for [now] and returns the resulting streak.
  ///
  /// Safe to call repeatedly — the first close of the day is what counts.
  static int recordRingClosed({required PrefsService prefs, DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayKey = _key(today);
    if (prefs.lastActiveDate == todayKey) {
      if (prefs.currentStreak > 0) return prefs.currentStreak;
      prefs.currentStreak = 1;
      if (prefs.longestStreak < 1) prefs.longestStreak = 1;
      return 1;
    }

    final yesterdayKey = _key(today.subtract(const Duration(days: 1)));
    final next = prefs.lastActiveDate == yesterdayKey
        ? (prefs.currentStreak == 0 ? 1 : prefs.currentStreak + 1)
        : 1;

    prefs.currentStreak = next;
    prefs.lastActiveDate = todayKey;
    if (next > prefs.longestStreak) prefs.longestStreak = next;
    return next;
  }

  /// The streak as it should be shown — 0 once it has actually lapsed.
  ///
  /// Stored streaks go stale the moment a day is skipped, so a user who stopped
  /// a week ago must not still see their old number.
  static int visibleStreak({required PrefsService prefs, DateTime? now}) {
    final today = now ?? DateTime.now();
    final last = prefs.lastActiveDate;
    if (last == null || last.isEmpty) return 0;
    if (last == _key(today)) return prefs.currentStreak;
    if (last == _key(today.subtract(const Duration(days: 1)))) {
      return prefs.currentStreak;
    }
    return 0;
  }

  /// Whether today has already fed the streak.
  static bool closedToday({required PrefsService prefs, DateTime? now}) =>
      prefs.lastActiveDate == _key(now ?? DateTime.now());

  /// Marks [now] as a day where every available ring was closed. Idempotent.
  static void recordFullDay({required PrefsService prefs, DateTime? now}) {
    final todayKey = _key(now ?? DateTime.now());
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
    final today = now ?? DateTime.now();
    final keys = <String>{
      for (var i = 0; i < 7; i++)
        _key(today.subtract(Duration(days: i))),
    };
    return prefs.todayFullDayDates.where(keys.contains).length;
  }
}
