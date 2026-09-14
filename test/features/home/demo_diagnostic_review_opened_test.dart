import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/domain/demo_diagnostic_ephemeral_store.dart';

void main() {
  group('shouldMarkDemoDiagnosticReviewOpened', () {
    test('marks when the session is the demo diagnostic', () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: true,
          getStartedDiagnosticAttempted: false,
        ),
        isTrue,
      );
    });

    test('marks when the demo was attempted even if the session key is missing',
        () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: false,
          getStartedDiagnosticAttempted: true,
        ),
        isTrue,
      );
    });

    test('does not mark when the user never took the demo', () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: false,
          getStartedDiagnosticAttempted: false,
        ),
        isFalse,
      );
    });
  });
}
