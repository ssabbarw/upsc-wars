import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_schedule.dart';

void main() {
  group('DailyCaSchedule', () {
    test('Sunday is not a test day', () {
      // 2026-06-07 is a Sunday
      final sunday = DateTime(2026, 6, 7, 12);
      expect(DailyCaSchedule.isTestDay(sunday), isFalse);
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

    test('Monday re-serves Saturday because Sunday has no paper', () {
      // Monday 8 June 2026, 8 AM → Saturday 6 June (Sunday 7th is off).
      final ref = DateTime(2026, 6, 8, 8);
      final date = DailyCaSchedule.paperQuizContentDate(referenceIst: ref);
      expect(date, DateTime(2026, 6, 6));
      expect(DailyCaSchedule.isTodaysPaper(date!, referenceIst: ref), isFalse);
    });

    test('Sunday morning still has Saturday\'s paper', () {
      final date = DailyCaSchedule.paperQuizContentDate(
        referenceIst: DateTime(2026, 6, 7, 9),
      );
      expect(date, DateTime(2026, 6, 6));
    });

    test('next open skips the Monday gap', () {
      // Sunday 10 AM: Monday brings nothing new, so Tuesday 6 AM is next.
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
