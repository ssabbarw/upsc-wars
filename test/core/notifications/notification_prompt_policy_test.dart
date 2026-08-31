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
    test('first-test copy leads with the demo and lists what’s next', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.postFirstTest,
        flags: const NotificationPromptFlags(
          dailyCa: true,
          caShots: true,
          community: true,
        ),
      );
      expect(copy.title.toLowerCase(), contains('liked this test'));
      final bullets = copy.bullets.join(' ').toLowerCase();
      expect(bullets, contains('revision games'));
      expect(bullets, contains('1v1'));
      expect(bullets, contains('current affairs'));
      expect(bullets, contains('ca shots'));
      expect(bullets, contains('pyq'));
      expect(bullets, isNot(contains('daily battle')));
      expect(copy.alsoLine.toLowerCase(), contains('nudge'));
      expect(copy.cta.toLowerCase(), contains('notify'));
    });

    test('first-test copy omits RC-gated items when flags are off', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.postFirstTest,
      );
      final bullets = copy.bullets.join(' ').toLowerCase();
      expect(bullets, contains('revision games'));
      expect(bullets, contains('pyq'));
      expect(bullets, isNot(contains('current affairs')));
      expect(bullets, isNot(contains('ca shots')));
      expect(bullets, isNot(contains('1v1')));
      expect(bullets, isNot(contains('daily battle')));
    });

    test('first-test copy when demo review was skipped is honest, not a pitch-only pivot', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.postFirstTest,
        skippedDemoReview: true,
        flags: const NotificationPromptFlags(dailyCa: true),
      );
      expect(copy.title.toLowerCase(), contains('explanations'));
      expect(copy.title.toLowerCase(), isNot(contains('liked this test')));
      expect(copy.body.toLowerCase(), contains('review'));
      expect(copy.body.toLowerCase(), contains('upsc wars'));
      expect(copy.alsoLine.toLowerCase(), contains('nudge'));
      expect(copy.bullets.join(' ').toLowerCase(), contains('revision games'));
      expect(copy.cta.toLowerCase(), contains('notify'));
    });

    test('first-test copy includes Daily Battle when enabled', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.postFirstTest,
        flags: const NotificationPromptFlags(dailyWar: true),
      );
      expect(copy.bullets.join(' ').toLowerCase(), contains('daily battle'));
    });

    test('war copy leads with Daily Battle and mentions other uses', () {
      final copy = NotificationPromptCopy.forSurface(
        NotificationPromptSurface.dailyWar,
      );
      expect(copy.title.toLowerCase(), contains('daily battle'));
      expect(copy.body.toLowerCase(), contains('daily battle'));
      expect(copy.alsoLine.toLowerCase(), contains('daily ca'));
      expect(copy.alsoLine.toLowerCase(), isNot(contains('static war')));
    });
  });
}
