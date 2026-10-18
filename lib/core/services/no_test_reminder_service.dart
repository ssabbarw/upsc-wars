import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../analytics/activation_milestones.dart';
import '../providers/prefs_provider.dart';
import 'app_local_notifications_service.dart';

/// Reminds new installs to take their first test the day after install.
class NoTestReminderService {
  NoTestReminderService._();

  static const _reminderHour = 10;

  static bool _timezonesReady = false;

  /// Records install time for brand-new installs; skips legacy users.
  static void recordFirstInstallIfNeeded(PrefsService prefs) {
    if (prefs.firstInstallAtMs != null) return;
    if (prefs.hasActivationMilestone(ActivationMilestones.firstProcessLaunch)) {
      return;
    }
    prefs.firstInstallAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Calendar day after [installLocal], at [_reminderHour]:00 local time.
  @visibleForTesting
  static DateTime nextDayReminderLocalTime(DateTime installLocal) {
    final installDay = DateTime(
      installLocal.year,
      installLocal.month,
      installLocal.day,
    );
    return installDay
        .add(const Duration(days: 1))
        .copyWith(
          hour: _reminderHour,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
  }

  static Future<void> sync({
    required PrefsService prefs,
    required int completedSessionCount,
  }) async {
    if (kIsWeb) return;

    if (completedSessionCount > 0) {
      await AppLocalNotificationsService.cancelNoTestReminder();
      return;
    }

    final installMs = prefs.firstInstallAtMs;
    if (installMs == null || prefs.noTestReminderHandled) return;

    await _ensureTimezonesReady();

    final installLocal = DateTime.fromMillisecondsSinceEpoch(installMs);
    final fireAtLocal = nextDayReminderLocalTime(installLocal);
    final now = DateTime.now();

    if (!fireAtLocal.isAfter(now)) {
      await AppLocalNotificationsService.showNoTestReminder();
      prefs.noTestReminderHandled = true;
      return;
    }

    final scheduled = await AppLocalNotificationsService.scheduleNoTestReminder(
      fireAtLocal: fireAtLocal,
    );
    if (scheduled) {
      prefs.noTestReminderHandled = true;
    }
  }

  static Future<void> cancelAfterFirstTest() async {
    if (kIsWeb) return;
    await AppLocalNotificationsService.cancelNoTestReminder();
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
}
