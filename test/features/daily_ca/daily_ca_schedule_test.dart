import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_schedule.dart';

void main() {
  group('DailyCaSchedule', () {
    test('Saturday is not a test day', () {
      // 2026-06-06 is a Saturday
      final saturday = DateTime(2026, 6, 6, 12);
      expect(DailyCaSchedule.isTestDay(saturday), isFalse);
      expect(DailyCaSchedule.isSaturday(saturday), isTrue);
    });

    test('Sunday is a test day (weekend pack)', () {
      final sunday = DateTime(2026, 6, 7, 12);
      expect(DailyCaSchedule.isTestDay(sunday), isTrue);
      expect(DailyCaSchedule.isSunday(sunday), isTrue);
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

    test('Sunday pack is hidden until Monday 6 AM', () {
      final sunday = DateTime(2026, 6, 7);
      expect(
        DailyCaSchedule.isPublishedForDate(
          sunday,
          referenceIst: DateTime(2026, 6, 7, 21),
        ),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(
          sunday,
          referenceIst: DateTime(2026, 6, 8, 5, 59),
        ),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(
          sunday,
          referenceIst: DateTime(2026, 6, 8, 6),
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
      // Tuesday 3 AM — Monday's news has not opened yet, so Sunday stands.
      final date = DailyCaSchedule.paperQuizContentDate(
        referenceIst: DateTime(2026, 6, 9, 3),
      );
      expect(date, DateTime(2026, 6, 7));
    });

    test('Monday serves Sunday\'s weekend pack', () {
      // Monday 8 June 2026, 8 AM → Sunday 7 June (Saturday 6th is off).
      final ref = DateTime(2026, 6, 8, 8);
      final date = DailyCaSchedule.paperQuizContentDate(referenceIst: ref);
      expect(date, DateTime(2026, 6, 7));
      expect(DailyCaSchedule.isTodaysPaper(date!, referenceIst: ref), isTrue);
    });

    test('Sunday morning falls back to Friday\'s paper', () {
      final date = DailyCaSchedule.paperQuizContentDate(
        referenceIst: DateTime(2026, 6, 7, 9),
      );
      expect(date, DateTime(2026, 6, 5));
    });

    test('next open skips the Sunday-morning gap', () {
      // Saturday 10 AM: next fresh pack is Monday 6 AM (Sunday's news).
      expect(
        DailyCaSchedule.nextOpensAt(referenceIst: DateTime(2026, 6, 6, 10)),
        DateTime(2026, 6, 8, 6),
      );
      // Sunday 10 AM: weekend pack opens Monday 6 AM.
      expect(
        DailyCaSchedule.nextOpensAt(referenceIst: DateTime(2026, 6, 7, 10)),
        DateTime(2026, 6, 8, 6),
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
        DailyCaSchedule.isOnOrAfterMinDate(DateTime(2026, 6, 4), min),
        isFalse,
      );
      expect(
        DailyCaSchedule.isOnOrAfterMinDate(DateTime(2026, 6, 5), min),
        isTrue,
      );
      expect(DailyCaSchedule.defaultCalendarMinDateIso, '2026-06-05');
    });

    test('parseCalendarMinDate accepts YYYY-MM-DD from Remote Config', () {
      expect(
        DailyCaSchedule.parseCalendarMinDate('2026-06-05'),
        DateTime(2026, 6, 5),
      );
      expect(
        DailyCaSchedule.parseCalendarMinDate('2026-6-5'),
        DateTime(2026, 6, 5),
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
  });
}
