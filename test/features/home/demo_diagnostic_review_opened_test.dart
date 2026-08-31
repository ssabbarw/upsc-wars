import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/domain/demo_diagnostic_ephemeral_store.dart';

void main() {
  group('shouldMarkDemoDiagnosticReviewOpened', () {
    test('marks when the session is the demo diagnostic', () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: true,
          getStartedDiagnosticAttempted: false,
          pushPromptPendingAfterFirstTest: false,
        ),
        isTrue,
      );
    });

    test('marks when first-test notif prompt is still waiting after the demo', () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: false,
          getStartedDiagnosticAttempted: true,
          pushPromptPendingAfterFirstTest: true,
        ),
        isTrue,
      );
    });

    test('does not mark a later session review after the prompt already fired', () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: false,
          getStartedDiagnosticAttempted: true,
          pushPromptPendingAfterFirstTest: false,
        ),
        isFalse,
      );
    });

    test('does not mark when the user never took the demo', () {
      expect(
        shouldMarkDemoDiagnosticReviewOpened(
          isDemoSession: false,
          getStartedDiagnosticAttempted: false,
          pushPromptPendingAfterFirstTest: true,
        ),
        isFalse,
      );
    });
  });
}
