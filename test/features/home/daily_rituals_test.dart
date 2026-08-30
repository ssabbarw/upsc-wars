import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/domain/daily_rituals.dart';

void main() {
  group('DailyRituals.shouldShowIntro', () {
    test('waits until onboarding is done', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: false,
          introSeen: false,
          openedIds: const {},
        ),
        isFalse,
      );
    });

    test('shows once after onboarding when rituals are unread', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: false,
          openedIds: const {},
        ),
        isTrue,
      );
    });

    test('does not show again after dismiss', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: true,
          openedIds: const {},
        ),
        isFalse,
      );
    });

    test('skips users who already opened all three rituals', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: false,
          openedIds: DailyRitualIds.all,
        ),
        isFalse,
      );
    });

    test('still shows when only some rituals were opened', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: false,
          openedIds: {DailyRitualIds.caShots},
        ),
        isTrue,
      );
    });

    test('hides when no remote-enabled rituals', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: false,
          openedIds: const {},
          enabledIds: const {},
        ),
        isFalse,
      );
    });

    test('skips when every enabled ritual was already opened', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: false,
          openedIds: {DailyRitualIds.caShots},
          enabledIds: {DailyRitualIds.caShots},
        ),
        isFalse,
      );
    });

    test('shows when an enabled ritual is still unread', () {
      expect(
        DailyRituals.shouldShowIntro(
          onboardingSeen: true,
          introSeen: false,
          openedIds: {DailyRitualIds.caShots},
          enabledIds: {DailyRitualIds.caShots, DailyRitualIds.dailyCa},
        ),
        isTrue,
      );
    });
  });

  group('DailyRituals.enabledItems', () {
    test('returns nothing when all flags are off', () {
      expect(
        DailyRituals.enabledItems(
          caShotsEnabled: false,
          dailyCaEnabled: false,
          dailyWarEnabled: false,
        ),
        isEmpty,
      );
    });

    test('keeps only flags that are on, in sheet order', () {
      expect(
        DailyRituals.enabledItems(
          caShotsEnabled: true,
          dailyCaEnabled: false,
          dailyWarEnabled: true,
        ).map((r) => r.id).toList(),
        [DailyRitualIds.caShots, DailyRitualIds.dailyWar],
      );
    });
  });
}
