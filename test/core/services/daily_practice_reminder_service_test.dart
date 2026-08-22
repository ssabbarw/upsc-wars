import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/services/daily_practice_reminder_service.dart';

void main() {
  group('DailyPracticeReminderService.nextReminderLocalTime', () {
    test('returns today slot when reference is before the hour', () {
      final reference = DateTime(2026, 6, 11, 7, 30);
      final fireAt = DailyPracticeReminderService.nextReminderLocalTime(
        reference: reference,
        hour: 8,
      );
      expect(fireAt, DateTime(2026, 6, 11, 8, 0));
    });

    test('rolls to tomorrow when reference is on or after the hour', () {
      final reference = DateTime(2026, 6, 11, 8, 15);
      final fireAt = DailyPracticeReminderService.nextReminderLocalTime(
        reference: reference,
        hour: 8,
      );
      expect(fireAt, DateTime(2026, 6, 12, 8, 0));
    });
  });

  group('DailyPracticeReminderService.shouldFireToday', () {
    test('schedules when CA is revised and the queue is open', () {
      expect(
        DailyPracticeReminderService.shouldFireToday(
          activationComplete: true,
          paperRevised: true,
          practiceCompletedToday: false,
          queueEmpty: false,
        ),
        isTrue,
      );
    });

    test('does not schedule when CA is still unfinished', () {
      expect(
        DailyPracticeReminderService.shouldFireToday(
          activationComplete: true,
          paperRevised: false,
          practiceCompletedToday: false,
          queueEmpty: false,
        ),
        isFalse,
      );
    });

    test('does not schedule when the queue is empty', () {
      expect(
        DailyPracticeReminderService.shouldFireToday(
          activationComplete: true,
          paperRevised: true,
          practiceCompletedToday: false,
          queueEmpty: true,
        ),
        isFalse,
      );
    });

    test('does not schedule after the drill is done today', () {
      expect(
        DailyPracticeReminderService.shouldFireToday(
          activationComplete: true,
          paperRevised: true,
          practiceCompletedToday: true,
          queueEmpty: false,
        ),
        isFalse,
      );
    });
  });
}
