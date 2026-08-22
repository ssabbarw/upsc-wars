import 'package:flutter/foundation.dart';

import '../../features/daily_ca/domain/daily_ca_schedule.dart';
import '../constants/daily_drill_constants.dart';
import 'app_local_notifications_service.dart';
import 'daily_practice_reminder_service.dart';

/// Schedules the morning "your paper quiz is live" reminder.
///
/// One-shot rather than repeating, so each app open books the next valid
/// morning. Mornings where no fresh paper opens (Monday, since Sunday has no
/// newspaper) are skipped instead of promising a quiz that isn't new.
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
    if (!enabled) {
      await AppLocalNotificationsService.cancelDailyCaPaperReminder();
      return;
    }
    await DailyPracticeReminderService.ensureTimezonesReady();
    await AppLocalNotificationsService.scheduleDailyCaPaperReminder(
      fireAtLocal: fireAt(reference: DateTime.now(), skipToday: skipToday),
      questionCount: DailyDrillConstants.questionCount,
    );
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
