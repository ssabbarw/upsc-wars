import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../providers/prefs_provider.dart';
import 'app_local_notifications_service.dart';

/// Schedules one local reminder per day for the home Daily Drill.
class DailyPracticeReminderService {
  DailyPracticeReminderService._();

  /// Next local [hour]:00 on or after [reference], rolling to tomorrow when needed.
  static DateTime nextReminderLocalTime({
    required DateTime reference,
    required int hour,
  }) {
    final day = DateTime(reference.year, reference.month, reference.day);
    final todaySlot = day.copyWith(
      hour: hour.clamp(0, 23),
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    if (todaySlot.isAfter(reference)) return todaySlot;
    return todaySlot.add(const Duration(days: 1));
  }

  /// Fire today when the Daily Drill is still open. Independent of CA / queue.
  @visibleForTesting
  static bool shouldFireToday({required bool practiceCompletedToday}) {
    return !practiceCompletedToday;
  }

  static Future<void> sync({
    required PrefsService prefs,
    required bool eligible,
    required bool practiceCompletedToday,
  }) async {
    if (kIsWeb) return;

    if (!eligible) {
      await AppLocalNotificationsService.cancelDailyPracticeReminder();
      return;
    }

    await ensureTimezonesReady();

    final hour = prefs.dailyPracticeReminderHour;
    final fireToday = shouldFireToday(
      practiceCompletedToday: practiceCompletedToday,
    );
    final fireAt = fireToday
        ? nextReminderLocalTime(reference: DateTime.now(), hour: hour)
        : nextReminderLocalTime(
            reference: DateTime.now().add(const Duration(days: 1)),
            hour: hour,
          );

    await AppLocalNotificationsService.scheduleDailyPracticeReminder(
      fireAtLocal: fireAt,
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
