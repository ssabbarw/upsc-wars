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
  });
}
