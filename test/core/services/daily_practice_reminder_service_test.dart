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
    test('schedules when the drill is still open', () {
      expect(
        DailyPracticeReminderService.shouldFireToday(
          practiceCompletedToday: false,
        ),
        isTrue,
      );
    });

    test('does not schedule after the drill is done today', () {
      expect(
        DailyPracticeReminderService.shouldFireToday(
          practiceCompletedToday: true,
        ),
        isFalse,
      );
    });
  });
}
