import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/core/providers/soft_update_provider.dart';

void main() {
  const app = ReleaseVersion(3, 1, 0);

  group('resolveSoftUpdate', () {
    test('hides when kill switch is already blocking', () {
      final snap = resolveSoftUpdate(
        killSwitchActive: true,
        appVersion: app,
        rawRequired: '3.2',
        rawMessage: '',
        dismissedVersion: '',
      );
      expect(snap.shouldPrompt, isFalse);
    });

    test('prompts when RC minimum is ahead of this build', () {
      final snap = resolveSoftUpdate(
        killSwitchActive: false,
        appVersion: app,
        rawRequired: 'v3.2',
        rawMessage: '',
        dismissedVersion: '',
      );
      expect(snap.shouldPrompt, isTrue);
      expect(snap.requiredMinimum.toString(), '3.2.0');
      expect(snap.message, SoftUpdateSnapshot.defaultMessage);
    });

    test('uses the RC message when present', () {
      final snap = resolveSoftUpdate(
        killSwitchActive: false,
        appVersion: app,
        rawRequired: '3.2',
        rawMessage: '  New Daily Battle is live.  ',
        dismissedVersion: '',
      );
      expect(snap.message, 'New Daily Battle is live.');
    });

    test('hides after the user dismissed that minimum', () {
      final snap = resolveSoftUpdate(
        killSwitchActive: false,
        appVersion: app,
        rawRequired: '3.2',
        rawMessage: '',
        dismissedVersion: '3.2.0',
      );
      expect(snap.shouldPrompt, isFalse);
    });

    test('hides when this build already meets the minimum', () {
      final snap = resolveSoftUpdate(
        killSwitchActive: false,
        appVersion: const ReleaseVersion(3, 2, 0),
        rawRequired: '3.2',
        rawMessage: '',
        dismissedVersion: '',
      );
      expect(snap.shouldPrompt, isFalse);
    });

    test('hides when RC is empty or unparsable', () {
      expect(
        resolveSoftUpdate(
          killSwitchActive: false,
          appVersion: app,
          rawRequired: '',
          rawMessage: '',
          dismissedVersion: '',
        ).shouldPrompt,
        isFalse,
      );
      expect(
        resolveSoftUpdate(
          killSwitchActive: false,
          appVersion: app,
          rawRequired: 'not-a-version',
          rawMessage: '',
          dismissedVersion: '',
        ).shouldPrompt,
        isFalse,
      );
    });
  });
}
