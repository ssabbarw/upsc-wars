import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/daily_drill_constants.dart';
import '../presentation/session_subject_label.dart';
import '../providers/prefs_provider.dart';
import 'app_local_notifications_service.dart';

/// Schedules one local reminder per day for the home daily practice drill.
class DailyPracticeReminderService {
  DailyPracticeReminderService._();

  /// Next local [hour]:00 on or after [reference], rolling to tomorrow when needed.
  @visibleForTesting
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

  static Future<void> sync({
    required PrefsService prefs,
    required bool activationComplete,
    required bool completedToday,
  }) async {
    if (kIsWeb) return;

    if (!activationComplete) {
      await AppLocalNotificationsService.cancelDailyPracticeReminder();
      return;
    }

    await _ensureTimezonesReady();

    final hour = prefs.dailyPracticeReminderHour;
    final subjectLabel =
        displayNameForSessionSubject(prefs.dailyPracticeSubject);
    final fireAt = completedToday
        ? nextReminderLocalTime(
            reference: DateTime.now().add(const Duration(days: 1)),
            hour: hour,
          )
        : nextReminderLocalTime(reference: DateTime.now(), hour: hour);

    await AppLocalNotificationsService.scheduleDailyPracticeReminder(
      fireAtLocal: fireAt,
      subjectDisplayName: subjectLabel,
    );
  }

  static Future<void> syncAfterSessionSubmit({
    required PrefsService prefs,
    required String? analyticsFeatureKey,
  }) async {
    if (analyticsFeatureKey != DailyDrillConstants.analyticsKey) return;
    await sync(
      prefs: prefs,
      activationComplete: prefs.homeActivationComplete,
      completedToday: true,
    );
  }

  static Future<void> _ensureTimezonesReady() async {
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
