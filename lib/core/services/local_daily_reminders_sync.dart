import '../database/user_db.dart';
import '../providers/prefs_provider.dart';
import '../../features/daily_ca/domain/daily_ca_schedule.dart';
import '../../features/daily_war/domain/daily_war_schedule.dart';
import '../../features/home/domain/daily_revision.dart';
import '../../features/home/domain/today_hero.dart';
import 'daily_ca_reminder_service.dart';
import 'daily_practice_reminder_service.dart';

/// Keeps afternoon drill + morning paper local reminders aligned with prefs.
class LocalDailyRemindersSync {
  LocalDailyRemindersSync._();

  static Future<void> sync({
    required PrefsService prefs,
    required UserDatabase db,
    required bool dailyCaEnabled,
  }) async {
    await syncPractice(prefs: prefs, db: db, dailyCaEnabled: dailyCaEnabled);
    final skipTodayPaper = await _paperCompletedToday(db: db);
    await DailyCaReminderService.sync(
      enabled: dailyCaEnabled,
      skipToday: skipTodayPaper,
    );
  }

  /// Re-evaluate the revision-queue reminder after a session or CA results.
  static Future<void> syncPractice({
    required PrefsService prefs,
    required UserDatabase db,
    required bool dailyCaEnabled,
  }) async {
    final flags = await _resolvePracticeFlags(
      prefs: prefs,
      db: db,
      dailyCaEnabled: dailyCaEnabled,
    );
    await DailyPracticeReminderService.sync(
      prefs: prefs,
      activationComplete: prefs.homeActivationComplete,
      paperRevised: flags.paperRevised,
      practiceCompletedToday: flags.practiceCompletedToday,
      queueEmpty: flags.queueEmpty,
    );
  }

  static Future<
    ({bool paperRevised, bool practiceCompletedToday, bool queueEmpty})
  >
  _resolvePracticeFlags({
    required PrefsService prefs,
    required UserDatabase db,
    required bool dailyCaEnabled,
  }) async {
    final ist = DailyWarSchedule.nowIst();
    final paperDate = dailyCaEnabled
        ? DailyCaSchedule.paperQuizContentDate(referenceIst: ist)
        : null;
    final paperIso = paperDate == null
        ? null
        : DailyCaSchedule.formatIsoDate(paperDate);
    final paperRevised =
        !dailyCaEnabled ||
        paperIso == null ||
        prefs.hasOpenedDailyCaResults(paperIso);
    final practiceCompletedToday = await db.sessionsDao
        .hasCompletedDailyDrillBetween(
          startInclusive: TodayHero.hubWindowStart(ist),
          endExclusive: TodayHero.hubWindowEnd(ist),
        );
    final wrong = await DailyRevision.countWrongUuids(db);
    final saved = await DailyRevision.countBookmarks(db);
    return (
      paperRevised: paperRevised,
      practiceCompletedToday: practiceCompletedToday,
      queueEmpty: wrong <= 0 && saved <= 0,
    );
  }

  static Future<bool> _paperCompletedToday({required UserDatabase db}) async {
    final paperDate = DailyCaSchedule.paperQuizContentDate();
    if (paperDate == null) return false;
    final iso = DailyCaSchedule.formatIsoDate(paperDate);
    return db.sessionsDao.hasCompletedDailyCa(iso);
  }
}
