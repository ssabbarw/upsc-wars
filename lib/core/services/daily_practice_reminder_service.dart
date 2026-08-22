import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../providers/prefs_provider.dart';
import 'app_local_notifications_service.dart';

/// Schedules one local reminder per day for the home revision-queue loop.
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

  /// Fire today only when the queue would be the Today-hub hero: CA revised
  /// (or no paper), queue non-empty, and the drill not yet done.
  @visibleForTesting
  static bool shouldFireToday({
    required bool activationComplete,
    required bool paperRevised,
    required bool practiceCompletedToday,
    required bool queueEmpty,
  }) {
    return activationComplete &&
        paperRevised &&
        !practiceCompletedToday &&
        !queueEmpty;
  }

  static Future<void> sync({
    required PrefsService prefs,
    required bool activationComplete,
    required bool paperRevised,
    required bool practiceCompletedToday,
    required bool queueEmpty,
  }) async {
    if (kIsWeb) return;

    if (!activationComplete || queueEmpty) {
      await AppLocalNotificationsService.cancelDailyPracticeReminder();
      return;
    }

    await ensureTimezonesReady();

    final hour = prefs.dailyPracticeReminderHour;
    final fireToday = shouldFireToday(
      activationComplete: activationComplete,
      paperRevised: paperRevised,
      practiceCompletedToday: practiceCompletedToday,
      queueEmpty: queueEmpty,
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
