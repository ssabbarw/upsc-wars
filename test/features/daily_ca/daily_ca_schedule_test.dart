import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_schedule.dart';

void main() {
  group('DailyCaSchedule', () {
    test('nowIst is a civil IST clock so 6 AM countdowns are not short by ~5h', () {
      // 19:23 IST = 13:53 UTC. Next open Tuesday 6:00 IST is ~10h 37m later.
      final ist = DailyCaSchedule.nowIst(DateTime.utc(2026, 8, 17, 13, 53));
      expect(ist.isUtc, isFalse);
      expect(ist.hour, 19);
      expect(ist.minute, 23);
      final opens = DateTime(2026, 8, 18, 6);
      expect(opens.difference(ist).inHours, 10);
    });

    test('Sunday is not a test day', () {
      // 2026-06-07 is a Sunday
      final sunday = DateTime(2026, 6, 7, 12);
      expect(DailyCaSchedule.isTestDay(sunday), isFalse);
      expect(DailyCaSchedule.isSunday(sunday), isTrue);
    });

    test('Saturday is a test day', () {
      final saturday = DateTime(2026, 6, 6, 12);
      expect(DailyCaSchedule.isTestDay(saturday), isTrue);
      expect(DailyCaSchedule.isSaturday(saturday), isTrue);
    });

    test("a day's news opens the next morning, not the same night", () {
      final monday = DateTime(2026, 6, 8);
      expect(
        DailyCaSchedule.isPublishedForDate(
          monday,
          referenceIst: DateTime(2026, 6, 8, 21, 30),
        ),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(
          monday,
          referenceIst: DateTime(2026, 6, 9, 5, 59),
        ),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(
          monday,
          referenceIst: DateTime(2026, 6, 9, 6),
        ),
        isTrue,
      );
    });

    test('Sunday is never published', () {
      final sunday = DateTime(2026, 6, 7);
      expect(
        DailyCaSchedule.isPublishedForDate(
          sunday,
          referenceIst: DateTime(2026, 6, 8, 10),
        ),
        isFalse,
      );
    });

    test('Saturday paper opens Sunday 6 AM', () {
      final saturday = DateTime(2026, 6, 6);
      expect(
        DailyCaSchedule.isPublishedForDate(
          saturday,
          referenceIst: DateTime(2026, 6, 6, 21),
        ),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(
          saturday,
          referenceIst: DateTime(2026, 6, 7, 5, 59),
        ),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(
          saturday,
          referenceIst: DateTime(2026, 6, 7, 6),
        ),
        isTrue,
      );
    });

    test('past test days are published', () {
      final monday = DateTime(2026, 6, 1);
      final later = DateTime(2026, 6, 10, 10);
      expect(
        DailyCaSchedule.isPublishedForDate(monday, referenceIst: later),
        isTrue,
      );
    });

    test('morning serves yesterday\'s paper', () {
      // Tuesday 9 June 2026, 7 AM → Monday 8 June's news.
      final date = DailyCaSchedule.paperQuizContentDate(
        referenceIst: DateTime(2026, 6, 9, 7),
      );
      expect(date, DateTime(2026, 6, 8));
      expect(
        DailyCaSchedule.isTodaysPaper(
          date!,
          referenceIst: DateTime(2026, 6, 9, 7),
        ),
        isTrue,
      );
    });

    test('before 6 AM the previous morning\'s paper is still current', () {
      // Tuesday 3 AM — Monday's news has not opened yet, so Saturday stands.
      final date = DailyCaSchedule.paperQuizContentDate(
        referenceIst: DateTime(2026, 6, 9, 3),
      );
      expect(date, DateTime(2026, 6, 6));
    });

    test('Monday morning still serves Saturday\'s paper', () {
      // Monday 8 June 2026, 8 AM → Saturday 6 June (Sunday is off).
      final ref = DateTime(2026, 6, 8, 8);
      final date = DailyCaSchedule.paperQuizContentDate(referenceIst: ref);
      expect(date, DateTime(2026, 6, 6));
    });

    test('Sunday morning serves Saturday\'s paper', () {
      final date = DailyCaSchedule.paperQuizContentDate(
        referenceIst: DateTime(2026, 6, 7, 9),
      );
      expect(date, DateTime(2026, 6, 6));
      expect(
        DailyCaSchedule.isTodaysPaper(
          date!,
          referenceIst: DateTime(2026, 6, 7, 9),
        ),
        isTrue,
      );
    });

    test('next open skips the Monday-morning gap', () {
      // Saturday 10 AM: next fresh pack is Sunday 6 AM (Saturday's news).
      expect(
        DailyCaSchedule.nextOpensAt(referenceIst: DateTime(2026, 6, 6, 10)),
        DateTime(2026, 6, 7, 6),
      );
      // Sunday 10 AM: Monday has no Sunday paper, so Tuesday 6 AM.
      expect(
        DailyCaSchedule.nextOpensAt(referenceIst: DateTime(2026, 6, 7, 10)),
        DateTime(2026, 6, 9, 6),
      );
      // Tuesday 3 AM: Monday's news opens in three hours.
      expect(
        DailyCaSchedule.nextOpensAt(referenceIst: DateTime(2026, 6, 9, 3)),
        DateTime(2026, 6, 9, 6),
      );
    });

    test('countdown shows seconds under one minute', () {
      expect(
        DailyCaSchedule.formatCountdown(const Duration(seconds: 45)),
        '45s',
      );
      expect(
        DailyCaSchedule.formatCountdown(const Duration(minutes: 2, seconds: 5)),
        '00:02',
      );
    });

    test('min date blocks earlier calendar days', () {
      final min = DailyCaSchedule.defaultCalendarMinDate;
      expect(
        DailyCaSchedule.isOnOrAfterMinDate(DateTime(2026, 8, 17), min),
        isFalse,
      );
      expect(
        DailyCaSchedule.isOnOrAfterMinDate(DateTime(2026, 8, 18), min),
        isTrue,
      );
      expect(DailyCaSchedule.defaultCalendarMinDateIso, '2026-08-18');
    });

    test('parseCalendarMinDate accepts YYYY-MM-DD from Remote Config', () {
      expect(
        DailyCaSchedule.parseCalendarMinDate('2026-08-18'),
        DateTime(2026, 8, 18),
      );
      expect(
        DailyCaSchedule.parseCalendarMinDate('2026-8-18'),
        DateTime(2026, 8, 18),
      );
      expect(
        DailyCaSchedule.parseCalendarMinDate('2026-06-05'),
        DateTime(2026, 8, 18),
      );
      expect(
        DailyCaSchedule.parseCalendarMinDate(''),
        DailyCaSchedule.defaultCalendarMinDate,
      );
      expect(
        DailyCaSchedule.parseCalendarMinDate('invalid'),
        DailyCaSchedule.defaultCalendarMinDate,
      );
    });

    test('month navigation stays within min date and current month', () {
      final minMonth = DateTime(2026, 8);
      final currentMonth = DateTime(2026, 8);
      expect(DailyCaSchedule.isMonthBefore(2026, 7, minMonth), isTrue);
      expect(DailyCaSchedule.isMonthBefore(2026, 8, minMonth), isFalse);
      expect(DailyCaSchedule.isMonthAfter(2026, 9, currentMonth), isTrue);
      expect(DailyCaSchedule.isMonthAfter(2026, 8, currentMonth), isFalse);
    });
  });
}
