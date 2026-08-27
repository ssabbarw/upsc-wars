import 'package:flutter/foundation.dart';

import '../../features/daily_ca/domain/daily_ca_schedule.dart';
import 'app_local_notifications_service.dart';
import 'daily_practice_reminder_service.dart';

/// Morning "paper quiz is live" used to be a local one-shot. That push is now
/// an FCM topic broadcast (`notifyDailyCaPaper` at 7 AM IST) so guests on the
/// latest build get it too. [sync] only clears leftover local schedules.
class DailyCaReminderService {
  DailyCaReminderService._();

  /// Local hour for the reminder — an hour after the quiz opens at 6 AM IST.
  static const reminderHourLocal = 7;

  @visibleForTesting
  static DateTime nextReminderLocalTime({required DateTime reference}) {
    var slot = DailyPracticeReminderService.nextReminderLocalTime(
      reference: reference,
      hour: reminderHourLocal,
    );
    // A morning only carries a new paper if the day before was a content day.
    for (var i = 0; i < 8; i++) {
      if (DailyCaSchedule.isTestDay(slot.subtract(const Duration(days: 1)))) {
        return slot;
      }
      slot = slot.add(const Duration(days: 1));
    }
    return slot;
  }

  static Future<void> sync({
    required bool enabled,
    bool skipToday = false,
  }) async {
    if (kIsWeb) return;
    // Paper-live push is an FCM topic send (`notifyDailyCaPaper` at 7 AM IST).
    // Cancel any leftover local schedule so the latest build is not double-notified.
    await AppLocalNotificationsService.cancelDailyCaPaperReminder();
  }

  /// Next valid 7 AM slot, skipping [reference]'s morning when [skipToday].
  @visibleForTesting
  static DateTime fireAt({
    required DateTime reference,
    required bool skipToday,
  }) {
    var slot = nextReminderLocalTime(reference: reference);
    if (!skipToday) return slot;
    final startOfTomorrow = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).add(const Duration(days: 1));
    if (!slot.isBefore(startOfTomorrow)) return slot;
    return nextReminderLocalTime(reference: slot);
  }
}
