import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/domain/sunday_week_review.dart';

void main() {
  group('SundayWeekReview.weekStartMonday', () {
    test('Sunday maps to the Monday that opened this week', () {
      // 16 Aug 2026 is a Sunday → week started 10 Aug.
      expect(
        SundayWeekReview.weekStartMonday(DateTime(2026, 8, 16, 19)),
        DateTime(2026, 8, 10),
      );
    });

    test('Monday is the start of its own week', () {
      expect(
        SundayWeekReview.weekStartMonday(DateTime(2026, 8, 10, 7)),
        DateTime(2026, 8, 10),
      );
    });

    test('exclusive end is the following Monday', () {
      expect(
        SundayWeekReview.weekEndExclusive(DateTime(2026, 8, 16)),
        DateTime(2026, 8, 17),
      );
    });
  });
}
