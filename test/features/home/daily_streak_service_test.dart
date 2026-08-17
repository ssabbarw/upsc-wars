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

    test('a skipped day restarts at one but keeps the record', () {
      prefs.currentStreak = 9;
      prefs.longestStreak = 9;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 10));
      final next = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(next, 1);
      expect(prefs.longestStreak, 9);
    });

    test('streaks earned under the old app-open rule carry over', () {
      // Existing install: 12-day streak last touched yesterday.
      prefs.currentStreak = 12;
      prefs.lastActiveDate = _key(DateTime(2026, 8, 16));
      final next = DailyStreakService.recordRingClosed(
        prefs: prefs,
        now: DateTime(2026, 8, 17),
      );
      expect(next, 13);
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

    test('a lapsed streak shows zero rather than a stale number', () {
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

  group('DailyStreakService full days', () {
    test('recording is idempotent and counted for the week', () {
      final now = DateTime(2026, 8, 17);
      DailyStreakService.recordFullDay(prefs: prefs, now: now);
      DailyStreakService.recordFullDay(prefs: prefs, now: now);
      expect(prefs.todayFullDayDates.length, 1);
      expect(
        DailyStreakService.fullDaysThisWeek(prefs: prefs, now: now),
        1,
      );
    });

    test('full days older than a week drop out of the count', () {
      DailyStreakService.recordFullDay(
        prefs: prefs,
        now: DateTime(2026, 8, 1),
      );
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
