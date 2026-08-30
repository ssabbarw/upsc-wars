import '../analytics/activation_milestones.dart';
import '../database/user_db.dart';
import '../providers/prefs_provider.dart';
import '../../features/daily_ca/domain/daily_ca_schedule.dart';
import '../../features/daily_war/domain/daily_war_schedule.dart';
import '../../features/home/domain/today_hero.dart';
import 'daily_ca_reminder_service.dart';
import 'daily_practice_reminder_service.dart';

/// Keeps afternoon drill + leftover local CA schedules aligned with prefs.
class LocalDailyRemindersSync {
  LocalDailyRemindersSync._();

  static Future<void> sync({
    required PrefsService prefs,
    required UserDatabase db,
    required bool dailyCaEnabled,
  }) async {
    await syncPractice(prefs: prefs, db: db);
    final skipTodayPaper = await _paperCompletedToday(db: db);
    await DailyCaReminderService.sync(
      enabled: dailyCaEnabled,
      skipToday: skipTodayPaper,
    );
  }

  /// Re-evaluate the Daily Drill reminder after a session.
  static Future<void> syncPractice({
    required PrefsService prefs,
    required UserDatabase db,
  }) async {
    final ist = DailyWarSchedule.nowIst();
    final practiceCompletedToday = await db.sessionsDao
        .hasCompletedDailyDrillBetween(
          startInclusive: TodayHero.hubWindowStart(ist),
          endExclusive: TodayHero.hubWindowEnd(ist),
        );
    await DailyPracticeReminderService.sync(
      prefs: prefs,
      eligible: prefs.hasActivationMilestone(
        ActivationMilestones.firstTestDone,
      ),
      practiceCompletedToday: practiceCompletedToday,
    );
  }

  static Future<bool> _paperCompletedToday({required UserDatabase db}) async {
    final paperDate = DailyCaSchedule.paperQuizContentDate();
    if (paperDate == null) return false;
    final iso = DailyCaSchedule.formatIsoDate(paperDate);
    return db.sessionsDao.hasCompletedDailyCa(iso);
  }
}
