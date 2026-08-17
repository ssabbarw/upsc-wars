import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/domain/daily_revision.dart';

void main() {
  group('DailyRevision.countsLine', () {
    test('both empty', () {
      expect(
        DailyRevision.countsLine(missed: 0, saved: 0),
        DailyRevision.emptyQueueLine,
      );
    });

    test('only incorrect', () {
      expect(DailyRevision.countsLine(missed: 12, saved: 0), '12 incorrect');
    });

    test('only bookmarked', () {
      expect(DailyRevision.countsLine(missed: 0, saved: 4), '4 bookmarked');
    });

    test('both', () {
      expect(
        DailyRevision.countsLine(missed: 12, saved: 4),
        '12 incorrect · 4 bookmarked',
      );
    });
  });

  group('DailyRevision.poolCountLabel', () {
    test('empty is None', () {
      expect(DailyRevision.poolCountLabel(0), 'None');
    });

    test('shows the count', () {
      expect(DailyRevision.poolCountLabel(12), '12');
    });
  });
}
