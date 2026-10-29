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
      expect(
        DailyRevision.countsLine(missed: 12, saved: 0),
        '12\u00a0incorrect',
      );
    });

    test('only bookmarked', () {
      expect(DailyRevision.countsLine(missed: 0, saved: 4), '4\u00a0bookmarks');
    });

    test('singular bookmark stays with its count', () {
      expect(
        DailyRevision.countsLine(missed: 5, saved: 1),
        '5\u00a0incorrect · 1\u00a0bookmark',
      );
    });

    test('both', () {
      expect(
        DailyRevision.countsLine(missed: 12, saved: 4),
        '12\u00a0incorrect · 4\u00a0bookmarks',
      );
    });

    test('stacked keeps each pool on its own line', () {
      expect(
        DailyRevision.countsStacked(missed: 5, saved: 1),
        '5\u00a0incorrect\n1\u00a0bookmark',
      );
    });
  });

  group('DailyRevision.randomTestSize', () {
    test('empty pool starts nothing', () {
      expect(DailyRevision.randomTestSize(0), 0);
      expect(DailyRevision.randomTestSize(-1), 0);
    });

    test('uses every question when fewer than 10', () {
      expect(DailyRevision.randomTestSize(1), 1);
      expect(DailyRevision.randomTestSize(9), 9);
    });

    test('caps a larger pool at 10', () {
      expect(DailyRevision.randomTestSize(10), 10);
      expect(DailyRevision.randomTestSize(18), 10);
      expect(DailyRevision.randomTestSize(24), 10);
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
