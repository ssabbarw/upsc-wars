import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_admin_cloud_service.dart';

void main() {
  group('DailyCaGenerateResult', () {
    test('parses a successful generate payload', () {
      final result = DailyCaGenerateResult.fromMap({
        'ok': true,
        'skipped': false,
        'date': '2026-08-25',
        'question_count': 15,
      });
      expect(result.wroteDraft, isTrue);
      expect(result.userMessage, contains('15 questions'));
    });

    test('already_exists is a skip, not a new draft', () {
      final result = DailyCaGenerateResult.fromMap({
        'ok': true,
        'skipped': true,
        'date': '2026-08-25',
        'question_count': 0,
        'reason': 'already_exists',
      });
      expect(result.wroteDraft, isFalse);
      expect(result.userMessage, contains('already exists'));
    });

    test('in_progress and sunday have specific copy', () {
      expect(
        DailyCaGenerateResult.fromMap({
          'ok': false,
          'skipped': true,
          'date': '2026-08-25',
          'reason': 'in_progress',
        }).userMessage,
        contains('already running'),
      );
      expect(
        DailyCaGenerateResult.fromMap({
          'ok': true,
          'skipped': true,
          'date': '2026-08-24',
          'reason': 'sunday',
        }).userMessage,
        contains('Sunday'),
      );
    });
  });
}
