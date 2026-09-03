import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../providers/prefs_provider.dart';
import 'app_local_notifications_service.dart';

/// Schedules a rolling week of local reminders for the home Daily Drill.
///
/// Nothing but an app open re-arms a local schedule, so keeping only the next
/// reminder pending goes silent after one skipped day. Holding a week of slots
/// keeps a lapsing user reachable without a server round trip.
class DailyPracticeReminderService {
  DailyPracticeReminderService._();

  /// How many days of reminders stay pending at once.
  static const windowDays = 7;

  /// Copy for a reminder firing [dayOffset] days after the window was built.
  ///
  /// Opening the app rebuilds the window, so [dayOffset] doubles as days since
  /// the last open and only an absent user reaches the later slots.
  /// [atRiskOffset] is the one slot where the streak genuinely expires that
  /// night; past it the streak has already lapsed and must not be claimed.
  @visibleForTesting
  static ({String title, String body}) copyForDayOffset({
    required int dayOffset,
    required int streak,
    required int? atRiskOffset,
  }) {
    const drill = (
      title: "Today's Daily Drill",
      body: '10 static MCQs. Keep the streak going.',
    );
    if (streak >= 2 &&
        atRiskOffset != null &&
        dayOffset == atRiskOffset) {
      return (
        title: 'Your $streak-day streak ends tonight',
        body: '10 static MCQs is all it takes to keep it.',
      );
    }
    if (dayOffset <= 1) return drill;
    if (dayOffset <= 3) {
      return (
        title: 'Pick your drill back up',
        body: '$dayOffset days off. 10 static MCQs puts today back on the board.',
      );
    }
    return (
      title: 'Your weak topics are still waiting',
      body: '10 MCQs from the ones you keep getting wrong. Five minutes.',
    );
  }

  /// Pending reminders for the next [windowDays] days, soonest first.
  ///
  /// Slots already past [now] are dropped, as is today's once the drill is done.
  /// [atRiskOffset] comes from [DailyStreakService.daysUntilStreakExpires] —
  /// the home streak survives one idle day, so "ends tonight" is the second.
  @visibleForTesting
  static List<ScheduledDrillReminder> buildWindow({
    required DateTime now,
    required int hour,
    required bool practiceCompletedToday,
    required int streak,
    required int? atRiskOffset,
  }) {
    final ids = AppLocalNotificationsService.dailyPracticeReminderWindowIds;

    final reminders = <ScheduledDrillReminder>[];
    for (var offset = 0; offset < windowDays; offset++) {
      if (reminders.length >= ids.length) break;
      final fireAt = DateTime(
        now.year,
        now.month,
        now.day + offset,
        hour.clamp(0, 23),
      );
      if (!fireAt.isAfter(now)) continue;
      if (offset == 0 && practiceCompletedToday) continue;
      final copy = copyForDayOffset(
        dayOffset: offset,
        streak: streak,
        atRiskOffset: atRiskOffset,
      );
      reminders.add((
        id: ids[reminders.length],
        fireAtLocal: fireAt,
        title: copy.title,
        body: copy.body,
      ));
    }
    return reminders;
  }

  static Future<void> sync({
    required PrefsService prefs,
    required bool eligible,
    required bool practiceCompletedToday,
    required int streak,
    required int? atRiskOffset,
  }) async {
    if (kIsWeb) return;

    if (!eligible) {
      await AppLocalNotificationsService.cancelDailyPracticeReminder();
      return;
    }

    await ensureTimezonesReady();

    await AppLocalNotificationsService.scheduleDailyPracticeReminders(
      buildWindow(
        now: DateTime.now(),
        hour: prefs.dailyPracticeReminderHour,
        practiceCompletedToday: practiceCompletedToday,
        streak: streak,
        atRiskOffset: atRiskOffset,
      ),
    );
  }

  static Future<void> ensureTimezonesReady() async {
    if (_timezonesReady) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
    _timezonesReady = true;
  }

  static bool _timezonesReady = false;
}
