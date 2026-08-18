import '../providers/prefs_provider.dart';
import '../../features/home/domain/daily_streak_service.dart';
import 'daily_ca_reminder_service.dart';
import 'daily_practice_reminder_service.dart';

/// Keeps afternoon drill + morning paper local reminders aligned with prefs.
class LocalDailyRemindersSync {
  LocalDailyRemindersSync._();

  static Future<void> sync({
    required PrefsService prefs,
    required bool dailyCaEnabled,
  }) async {
    await DailyPracticeReminderService.sync(
      prefs: prefs,
      activationComplete: prefs.homeActivationComplete,
      completedToday: DailyStreakService.closedToday(prefs: prefs),
    );
    await DailyCaReminderService.sync(enabled: dailyCaEnabled);
  }
}
