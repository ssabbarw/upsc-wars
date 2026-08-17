import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/services/daily_ca_reminder_service.dart';

void main() {
  group('DailyCaReminderService.nextReminderLocalTime', () {
    test('books 7 AM the same morning when it has not passed', () {
      // Tuesday 18 Aug 2026, 5 AM — Monday's paper opens at 6.
      expect(
        DailyCaReminderService.nextReminderLocalTime(
          reference: DateTime(2026, 8, 18, 5),
        ),
        DateTime(2026, 8, 18, 7),
      );
    });

    test('rolls to tomorrow once 7 AM has passed', () {
      expect(
        DailyCaReminderService.nextReminderLocalTime(
          reference: DateTime(2026, 8, 18, 9),
        ),
        DateTime(2026, 8, 19, 7),
      );
    });

    test('skips Monday morning because Sunday has no newspaper', () {
      // Sunday 16 Aug 2026, 9 AM → next fresh paper is Tuesday's 7 AM slot,
      // since Monday morning would only re-serve Saturday's paper.
      expect(
        DailyCaReminderService.nextReminderLocalTime(
          reference: DateTime(2026, 8, 16, 9),
        ),
        DateTime(2026, 8, 18, 7),
      );
    });

    test('Saturday evening books Sunday morning for Saturday\'s paper', () {
      expect(
        DailyCaReminderService.nextReminderLocalTime(
          reference: DateTime(2026, 8, 15, 20),
        ),
        DateTime(2026, 8, 16, 7),
      );
    });
  });
}
