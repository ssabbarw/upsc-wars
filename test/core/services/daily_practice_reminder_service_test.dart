import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/services/app_local_notifications_service.dart';
import 'package:upsc_wars/core/services/daily_practice_reminder_service.dart';

List<ScheduledDrillReminder> build({
  required DateTime now,
  int hour = 19,
  bool practiceCompletedToday = false,
  int streak = 0,
  bool streakClosedToday = false,
}) {
  return DailyPracticeReminderService.buildWindow(
    now: now,
    hour: hour,
    practiceCompletedToday: practiceCompletedToday,
    streak: streak,
    streakClosedToday: streakClosedToday,
  );
}

void main() {
  group('DailyPracticeReminderService.buildWindow', () {
    test('keeps a full week pending so a lapsed user stays reachable', () {
      final window = build(now: DateTime(2026, 6, 11, 7, 30));

      expect(window, hasLength(DailyPracticeReminderService.windowDays));
      expect(window.first.fireAtLocal, DateTime(2026, 6, 11, 19));
      expect(window.last.fireAtLocal, DateTime(2026, 6, 17, 19));
    });

    test('drops today when the hour has already passed', () {
      final window = build(now: DateTime(2026, 6, 11, 20, 15));

      expect(window.first.fireAtLocal, DateTime(2026, 6, 12, 19));
      expect(window, hasLength(6));
    });

    test('drops today when the drill is done, keeping the rest', () {
      final window = build(
        now: DateTime(2026, 6, 11, 7, 30),
        practiceCompletedToday: true,
      );

      expect(window.first.fireAtLocal, DateTime(2026, 6, 12, 19));
      expect(window, hasLength(6));
    });

    test('assigns distinct ids from the reserved pool', () {
      final window = build(now: DateTime(2026, 6, 11, 7, 30));
      final ids = window.map((r) => r.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(
        ids,
        everyElement(
          isIn(AppLocalNotificationsService.dailyPracticeReminderWindowIds),
        ),
      );
    });

    test('rolls across a month boundary', () {
      final window = build(now: DateTime(2026, 6, 28, 7, 30));

      expect(window.last.fireAtLocal, DateTime(2026, 7, 4, 19));
    });
  });

  group('DailyPracticeReminderService.copyForDayOffset', () {
    ({String title, String body}) copy({
      required int dayOffset,
      int streak = 0,
      int atRiskOffset = 0,
    }) {
      return DailyPracticeReminderService.copyForDayOffset(
        dayOffset: dayOffset,
        streak: streak,
        atRiskOffset: atRiskOffset,
      );
    }

    test('uses the plain drill nudge for the first two days', () {
      expect(copy(dayOffset: 0).title, "Today's Daily Drill");
      expect(copy(dayOffset: 1).title, "Today's Daily Drill");
    });

    test('warns about the streak only on the night it expires', () {
      expect(
        copy(dayOffset: 0, streak: 5, atRiskOffset: 0).title,
        'Your 5-day streak ends tonight',
      );
      expect(copy(dayOffset: 1, streak: 5, atRiskOffset: 0).title,
          "Today's Daily Drill");
    });

    test('shifts the warning a night later when today already counted', () {
      expect(copy(dayOffset: 0, streak: 5, atRiskOffset: 1).title,
          "Today's Daily Drill");
      expect(
        copy(dayOffset: 1, streak: 5, atRiskOffset: 1).title,
        'Your 5-day streak ends tonight',
      );
    });

    test('never claims a streak that is too short to lose', () {
      expect(copy(dayOffset: 0, streak: 1, atRiskOffset: 0).title,
          "Today's Daily Drill");
    });

    test('escalates to restart and then win-back copy', () {
      expect(copy(dayOffset: 2).title, 'Pick your drill back up');
      expect(copy(dayOffset: 2).body, startsWith('2 days off'));
      expect(copy(dayOffset: 3).title, 'Pick your drill back up');
      expect(
        copy(dayOffset: 4).title,
        'Your weak topics are still waiting',
      );
      expect(
        copy(dayOffset: 6).title,
        'Your weak topics are still waiting',
      );
    });
  });
}
