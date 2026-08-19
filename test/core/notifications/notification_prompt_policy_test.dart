import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/notifications/notification_prompt_policy.dart';

void main() {
  group('NotificationPromptPolicy.shouldShowAutomatic', () {
    final now = DateTime(2026, 8, 19, 17, 30);

    test('allows the first automatic show', () {
      expect(
        NotificationPromptPolicy.shouldShowAutomatic(
          automaticShownCount: 0,
          lastAutomaticShownAt: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('blocks after max automatic shows', () {
      expect(
        NotificationPromptPolicy.shouldShowAutomatic(
          automaticShownCount: NotificationPromptPolicy.maxAutomaticShows,
          lastAutomaticShownAt: now.subtract(const Duration(days: 3)),
          now: now,
        ),
        isFalse,
      );
    });

    test('blocks during the 24h cooldown', () {
      expect(
        NotificationPromptPolicy.shouldShowAutomatic(
          automaticShownCount: 1,
          lastAutomaticShownAt: now.subtract(const Duration(hours: 6)),
          now: now,
        ),
        isFalse,
      );
    });

    test('allows a second show after cooldown', () {
      expect(
        NotificationPromptPolicy.shouldShowAutomatic(
          automaticShownCount: 1,
          lastAutomaticShownAt: now.subtract(const Duration(hours: 25)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('NotificationPromptCopy', () {
    test('first-test copy leads with practice and mentions other uses', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.postFirstTest,
      );
      expect(copy.title.toLowerCase(), contains('practice'));
      expect(copy.alsoLine.toLowerCase(), contains('daily war'));
    });

    test('war copy leads with Daily War and mentions other uses', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.dailyWar,
      );
      expect(copy.title.toLowerCase(), contains('war'));
      expect(copy.body.toLowerCase(), contains('daily war'));
      expect(copy.alsoLine.toLowerCase(), contains('daily ca'));
      expect(copy.alsoLine.toLowerCase(), contains('battle'));
    });
  });
}
