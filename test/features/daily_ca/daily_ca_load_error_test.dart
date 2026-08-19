import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_load_error.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_repository.dart';

void main() {
  group('dailyCaUserFacingErrorMessage', () {
    test('missing paper does not mention Firebase or collection names', () {
      final message = dailyCaUserFacingErrorMessage(
        DailyCaNotAvailableException(
          '2026-08-17',
          firestorePath: 'daily_mcqs/2026/08/17',
        ),
      );
      expect(message, 'Questions for this date are not available yet.');
      expect(message.toLowerCase(), isNot(contains('firebase')));
      expect(message.toLowerCase(), isNot(contains('firestore')));
      expect(message, isNot(contains('daily_mcqs')));
    });

    test('permission denied does not mention Firebase or collection names', () {
      final message = dailyCaUserFacingErrorMessage(
        DailyCaPermissionDeniedException(
          '2026-08-17',
          firestorePath: 'daily_mcqs/2026/08/17',
        ),
      );
      expect(message.toLowerCase(), isNot(contains('firebase')));
      expect(message.toLowerCase(), isNot(contains('firestore')));
      expect(message, isNot(contains('daily_mcqs')));
    });

    test('raw Firestore exception does not leak internals', () {
      final message = dailyCaUserFacingErrorMessage(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No document to update: daily_mcqs/2026/08/17',
        ),
      );
      expect(message.toLowerCase(), isNot(contains('firebase')));
      expect(message.toLowerCase(), isNot(contains('firestore')));
      expect(message, isNot(contains('daily_mcqs')));
    });
  });

  group('DailyCaRepository.snapshotHasQuestions', () {
    test('true for a list of question maps', () {
      expect(
        DailyCaRepository.snapshotHasQuestions({
          'questions': [
            {'uuid': 'a'},
          ],
        }),
        isTrue,
      );
    });

    test('true for numeric-keyed question maps', () {
      expect(
        DailyCaRepository.snapshotHasQuestions({
          'questions': {
            '0': {'uuid': 'a'},
          },
        }),
        isTrue,
      );
    });

    test('false when missing or empty', () {
      expect(DailyCaRepository.snapshotHasQuestions(null), isFalse);
      expect(DailyCaRepository.snapshotHasQuestions({}), isFalse);
      expect(
        DailyCaRepository.snapshotHasQuestions({'questions': <Object>[]}),
        isFalse,
      );
    });
  });
}
