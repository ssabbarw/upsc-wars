import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';

void main() {
  group('demoTestAttemptBand', () {
    test('none when nothing is scored', () {
      expect(demoTestAttemptBand(attempted: 0, total: 8), 'none');
    });

    test('1_2 for one or two scored', () {
      expect(demoTestAttemptBand(attempted: 1, total: 8), '1_2');
      expect(demoTestAttemptBand(attempted: 2, total: 8), '1_2');
    });

    test('3_5 for three to five scored', () {
      expect(demoTestAttemptBand(attempted: 3, total: 8), '3_5');
      expect(demoTestAttemptBand(attempted: 5, total: 8), '3_5');
    });

    test('6_7 when almost done but not the full paper', () {
      expect(demoTestAttemptBand(attempted: 6, total: 8), '6_7');
      expect(demoTestAttemptBand(attempted: 7, total: 8), '6_7');
    });

    test('all when every question is scored', () {
      expect(demoTestAttemptBand(attempted: 8, total: 8), 'all');
      expect(demoTestAttemptBand(attempted: 4, total: 4), 'all');
    });
  });
}
