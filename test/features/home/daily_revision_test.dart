import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/domain/daily_revision.dart';

void main() {
  group('DailyRevision.countsLine', () {
    test('both empty is blank', () {
      expect(DailyRevision.countsLine(missed: 0, saved: 0), '');
    });

    test('only missed', () {
      expect(DailyRevision.countsLine(missed: 12, saved: 0), '12 missed');
    });

    test('only saved', () {
      expect(DailyRevision.countsLine(missed: 0, saved: 4), '4 saved');
    });

    test('both', () {
      expect(
        DailyRevision.countsLine(missed: 12, saved: 4),
        '12 missed · 4 saved',
      );
    });
  });

  group('DailyRevision.tryCta', () {
    test('empty', () {
      expect(DailyRevision.tryCta(0), 'None yet');
    });

    test('one', () {
      expect(DailyRevision.tryCta(1), 'Try this one');
    });

    test('under the cap', () {
      expect(DailyRevision.tryCta(3), 'Try these 3');
    });

    test('at the cap', () {
      expect(DailyRevision.tryCta(10), 'Try 10 of these');
    });

    test('over the cap still says 10', () {
      expect(DailyRevision.tryCta(40), 'Try 10 of these');
    });
  });
}
