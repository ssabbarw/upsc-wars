import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/services/no_test_reminder_service.dart';

void main() {
  group('NoTestReminderService.nextDayReminderLocalTime', () {
    test('fires at 10:00 on the calendar day after install', () {
      final install = DateTime(2026, 6, 8, 23, 45);
      final fireAt = NoTestReminderService.nextDayReminderLocalTime(install);
      expect(fireAt, DateTime(2026, 6, 9, 10, 0));
    });

    test('uses install calendar day, not 24h after install timestamp', () {
      final install = DateTime(2026, 6, 8, 9, 30);
      final fireAt = NoTestReminderService.nextDayReminderLocalTime(install);
      expect(fireAt, DateTime(2026, 6, 9, 10, 0));
    });
  });
}
