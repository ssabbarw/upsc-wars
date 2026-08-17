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
      expect(DailyRevision.countsLine(missed: 12, saved: 0), '12\u00a0incorrects');
    });

    test('only bookmarked', () {
      expect(DailyRevision.countsLine(missed: 0, saved: 4), '4\u00a0bookmarks');
    });

    test('singular bookmark stays with its count', () {
      expect(
        DailyRevision.countsLine(missed: 5, saved: 1),
        '5\u00a0incorrects · 1\u00a0bookmark',
      );
    });

    test('both', () {
      expect(
        DailyRevision.countsLine(missed: 12, saved: 4),
        '12\u00a0incorrects · 4\u00a0bookmarks',
      );
    });

    test('stacked keeps each pool on its own line', () {
      expect(
        DailyRevision.countsStacked(missed: 5, saved: 1),
        '5\u00a0incorrects\n1\u00a0bookmark',
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
