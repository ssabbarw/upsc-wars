import '../../../core/providers/prefs_provider.dart';
import 'daily_war_badges.dart';
import 'daily_war_schedule.dart';

/// Local War-night streak with a one-night grace, then tier demotion.
///
/// - Play consecutive War nights → streak days climb the 30-day badge ladder.
/// - Miss **one** War night → streak freezes (grace).
/// - Miss **two** consecutive War nights → demote one tier
///   ([DailyWarBadges.demoteStreakDays]); Sunday never counts as a miss.
abstract final class DailyWarStreak {
  DailyWarStreak._();

  /// Apply pending misses once the previous War night's live window has ended.
  static void reconcile({
    required PrefsService prefs,
    required DateTime istNow,
  }) {
    final lastId = prefs.dailyWarLastPlayedDateId;
    if (lastId == null || lastId.isEmpty) {
      if (prefs.dailyWarStreak != 0) prefs.dailyWarStreak = 0;
      if (prefs.dailyWarPendingMisses != 0) prefs.dailyWarPendingMisses = 0;
      return;
    }

    final today = DailyWarSchedule.warDateFor(istNow);
    final previous = DailyWarSchedule.previousWarDate(today);
    final previousEnd = DailyWarSchedule.liveEndsAt(previous);
    if (istNow.isBefore(previousEnd)) return;

    final last = DailyWarSchedule.parseIsoDate(lastId);
    // Still current through the previous War night — clear any stale grace.
    if (!last.isBefore(previous)) {
      if (prefs.dailyWarPendingMisses != 0) prefs.dailyWarPendingMisses = 0;
      return;
    }

    // How many War nights were missed after [last]?
    var cursor = DailyWarSchedule.nextWarDate(last);
    var missed = 0;
    while (cursor.isBefore(previous) || cursor == previous) {
      missed++;
      cursor = DailyWarSchedule.nextWarDate(cursor);
      if (missed > 14) break; // safety
    }

    if (missed <= 0) {
      prefs.dailyWarPendingMisses = 0;
      return;
    }

    if (missed == 1) {
      // Grace: keep streak days, remember one miss.
      prefs.dailyWarPendingMisses = 1;
      return;
    }

    // Two or more consecutive misses → demote once (not spiral to zero).
    var days = prefs.dailyWarStreak;
    days = DailyWarBadges.demoteStreakDays(days);
    // Extra misses beyond 2: one demotion per additional miss pair.
    var extra = missed - 2;
    while (extra >= 2 && days > 0) {
      days = DailyWarBadges.demoteStreakDays(days);
      extra -= 2;
    }
    prefs.dailyWarStreak = days;
    prefs.dailyWarPendingMisses = missed.isOdd ? 1 : 0;
  }

  /// Next streak days if [dateId] is played live (does not mutate prefs).
  static int peekNextDays({
    required PrefsService prefs,
    required String dateId,
  }) {
    final lastId = prefs.dailyWarLastPlayedDateId;
    if (lastId == dateId) return prefs.dailyWarStreak;

    final played = DailyWarSchedule.parseIsoDate(dateId);
    if (lastId == null || lastId.isEmpty) return 1;

    final last = DailyWarSchedule.parseIsoDate(lastId);
    final expectedPrev = DailyWarSchedule.previousWarDate(played);
    if (last == expectedPrev) {
      return prefs.dailyWarStreak + 1;
    }
    if (prefs.dailyWarPendingMisses == 1 &&
        DailyWarSchedule.previousWarDate(expectedPrev) == last) {
      return prefs.dailyWarStreak + 1;
    }
    if (prefs.dailyWarStreak > 0) return prefs.dailyWarStreak + 1;
    return 1;
  }

  /// Record a successful **live** (ranked) War attempt for [dateId].
  static void recordLivePlay({
    required PrefsService prefs,
    required String dateId,
  }) {
    final lastId = prefs.dailyWarLastPlayedDateId;
    if (lastId == dateId) return;

    final next = peekNextDays(prefs: prefs, dateId: dateId);
    prefs.dailyWarStreak = next < 1 ? 1 : next;
    prefs.dailyWarLastPlayedDateId = dateId;
    prefs.dailyWarPendingMisses = 0;
    if (prefs.dailyWarStreak > prefs.dailyWarLongestStreak) {
      prefs.dailyWarLongestStreak = prefs.dailyWarStreak;
    }
  }
}
