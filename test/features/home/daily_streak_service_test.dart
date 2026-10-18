import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/features/home/domain/daily_streak_service.dart';

String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

void main() {
  late PrefsService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsService(await SharedPreferences.getInstance());
  });

  group('DailyStreakService.recordRingClosed', () {
    test('a first closed ring starts the streak', () {
      final now = DateTime(2026, 8, 17, 7);
      expect(DailyStreakService.recordRingClosed(prefs: prefs, now: now), 1);
      expect(prefs.longestStreak, 1);
    });

    test('closing a second ring the same day does not double count', () {
      final now = DateTime(2026, 8, 17, 7);
      DailyStreakService.recordRingClosed(prefs: prefs, now: now);
      final again = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17, 21),
      );
      expect(again, 1);
    });

    test('consecutive days extend the streak', () {
      DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      final next = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 18),
      );
      expect(next, 2);
      expect(prefs.longestStreak, 2);
    });

    test('one skipped day is grace and still extends the streak', () {
      prefs.currentStreak = 9;
      prefs.longestStreak = 9;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      final next = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(next, 10);
      expect(prefs.longestStreak, 10);
    });

    test('two skipped days restart at one but keep the record', () {
      prefs.currentStreak = 9;
      prefs.longestStreak = 9;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 14));
      final next = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(next, 1);
      expect(prefs.longestStreak, 9);
    });

    test('streaks earned under the old app-open rule carry over', () {
      prefs.currentStreak = 12;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 16));
      final next = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(next, 13);
    });

    test('queues a one-time celebration at milestones', () {
      prefs.currentStreak = 2;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 16));
      DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(prefs.pendingStreakMilestoneCelebration, 3);
      expect(prefs.celebratedStreakMilestones, contains(3));

      DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 18),
      );
      // Already celebrated 3; no re-queue. Day 4 is not a milestone.
      expect(DailyStreakService.consumePendingMilestoneCelebration(prefs), 3);
      expect(prefs.pendingStreakMilestoneCelebration, isNull);
    });
  });

  group('DailyStreakService grace is capped', () {
    test('an unbroken run never spends the grace', () {
      DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 18),
      );
      expect(prefs.streakGraceUsedDates, isEmpty);
      expect(DailyStreakService.graceAvailable(prefs: prefs), isTrue);
    });

    test('a forgiven day is banked against the window', () {
      prefs.currentStreak = 9;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(prefs.streakGraceUsedDates, [_key(DateTime(2026, 8, 16))]);
    });

    test('a second skip inside the window breaks the streak', () {
      prefs.currentStreak = 9;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      // Aug 16 forgiven.
      expect(
        DailyStreakService.recordRingClosed(
          prefs: prefs,
          now: DateTime(2026, 8, 17),
        ),
        10,
      );
      // Aug 18 skipped too — no grace left, so this restarts.
      expect(
        DailyStreakService.recordRingClosed(
          prefs: prefs,
          now: DateTime(2026, 8, 19),
        ),
        1,
      );
      expect(prefs.longestStreak, 10);
    });

    test('grace recharges once the window has passed', () {
      prefs.currentStreak = 9;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 22));
      prefs.streakGraceUsedDates = [_key(DateTime(2026, 8, 16))];
      expect(
        DailyStreakService.recordRingClosed(
          prefs: prefs,
          now: DateTime(2026, 8, 24),
        ),
        10,
      );
    });

    test('a spent grace hides the streak on the idle day', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      prefs.streakGraceUsedDates = [_key(DateTime(2026, 8, 14))];
      expect(
        DailyStreakService.visibleStreak(
          prefs: prefs,
          now: DateTime(2026, 8, 17),
        ),
        0,
      );
    });

    test('a spent grace pulls the last-chance nudge a day earlier', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 17));
      prefs.streakGraceUsedDates = [_key(DateTime(2026, 8, 14))];
      expect(
        DailyStreakService.daysUntilStreakExpires(
          prefs: prefs,
          now: DateTime(2026, 8, 17, 20),
        ),
        1,
      );
    });
  });

  group('DailyStreakService.visibleStreak', () {
    test('today and yesterday both count as alive', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 17));
      expect(
        DailyStreakService.visibleStreak(
          prefs: prefs,
          now: DateTime(2026, 8, 17, 23),
        ),
        5,
      );
      expect(
        DailyStreakService.visibleStreak(
          prefs: prefs,
          now: DateTime(2026, 8, 18, 9),
        ),
        5,
      );
    });

    test('one grace day still shows the streak', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      expect(
        DailyStreakService.visibleStreak(
          prefs: prefs,
          now: DateTime(2026, 8, 17),
        ),
        5,
      );
    });

    test('two missed days show zero rather than a stale number', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 10));
      expect(
        DailyStreakService.visibleStreak(
          prefs: prefs,
          now: DateTime(2026, 8, 17),
        ),
        0,
      );
    });

    test('no history means no streak', () {
      expect(DailyStreakService.visibleStreak(prefs: prefs), 0);
    });
  });

  group('DailyStreakService.daysUntilStreakExpires', () {
    test('closed today — expires after the grace night (day +2)', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 17));
      expect(
        DailyStreakService.daysUntilStreakExpires(
          prefs: prefs,
          now: DateTime(2026, 8, 17, 20),
        ),
        2,
      );
    });

    test('last played yesterday — expires tomorrow night', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 16));
      expect(
        DailyStreakService.daysUntilStreakExpires(
          prefs: prefs,
          now: DateTime(2026, 8, 17, 10),
        ),
        1,
      );
    });

    test('already in grace — expires tonight', () {
      prefs.currentStreak = 5;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      expect(
        DailyStreakService.daysUntilStreakExpires(
          prefs: prefs,
          now: DateTime(2026, 8, 17, 10),
        ),
        0,
      );
    });

    test('short streaks are not at risk', () {
      prefs.currentStreak = 1;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 15));
      expect(
        DailyStreakService.daysUntilStreakExpires(
          prefs: prefs,
          now: DateTime(2026, 8, 17),
        ),
        isNull,
      );
    });
  });

  group('DailyStreakService full days', () {
    test('recording is idempotent and counted for the week', () {
      final now = DateTime(2026, 8, 17);
      DailyStreakService.recordFullDay(prefs: prefs, now: now);
      DailyStreakService.recordFullDay(prefs: prefs, now: now);
      expect(prefs.todayFullDayDates.length, 1);
      expect(DailyStreakService.fullDaysThisWeek(prefs: prefs, now: now), 1);
    });

    test('full days older than a week drop out of the count', () {
      DailyStreakService.recordFullDay(prefs: prefs, now: DateTime(2026, 8, 1));
      DailyStreakService.recordFullDay(
        prefs: prefs,
        now: DateTime(2026, 8, 16),
      );
      expect(
        DailyStreakService.fullDaysThisWeek(
          prefs: prefs,
          now: DateTime(2026, 8, 17),
        ),
        1,
      );
    });

    test('closedToday reflects whether today already fed the streak', () {
      final now = DateTime(2026, 8, 17, 10);
      expect(DailyStreakService.closedToday(prefs: prefs, now: now), isFalse);
      DailyStreakService.recordRingClosed(prefs: prefs, now: now);
      expect(DailyStreakService.closedToday(prefs: prefs, now: now), isTrue);
    });
  });
}
