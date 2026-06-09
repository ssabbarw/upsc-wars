import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_schedule.dart';

void main() {
  group('DailyCaSchedule', () {
    test('Sunday is not a test day', () {
      // 2026-06-07 is a Sunday
      final sunday = DateTime(2026, 6, 7, 12);
      expect(DailyCaSchedule.isTestDay(sunday), isFalse);
    });

    test('published after 9 PM IST on test day', () {
      final monday = DateTime(2026, 6, 8);
      final before = DateTime(2026, 6, 8, 20, 59);
      final after = DateTime(2026, 6, 8, 21, 0);
      expect(
        DailyCaSchedule.isPublishedForDate(monday, referenceIst: before),
        isFalse,
      );
      expect(
        DailyCaSchedule.isPublishedForDate(monday, referenceIst: after),
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
