import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_firestore.dart';

void main() {
  group('DailyCaFirestore', () {
    test('pathForDate uses daily_mcqs/year/month/day segments', () {
      expect(
        DailyCaFirestore.pathForDate('2026-06-08'),
        'daily_mcqs/2026/06/08',
      );
    });

    test('pathSegments zero-pads month and day', () {
      final s = DailyCaFirestore.pathSegments('2026-6-8');
      expect(s.year, '2026');
      expect(s.month, '06');
      expect(s.day, '08');
    });

    test('rejects invalid iso date', () {
      expect(
        () => DailyCaFirestore.pathForDate('08-06-2026'),
        throwsArgumentError,
      );
    });
  });
}
