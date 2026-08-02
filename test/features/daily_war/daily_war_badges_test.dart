import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_badges.dart';

void main() {
  group('DailyWarBadges ladder', () {
    test('maps streak days to tiers across 30 nights', () {
      expect(DailyWarBadges.tierIdForDays(0), isNull);
      expect(DailyWarBadges.tierIdForDays(1), 'recruit');
      expect(DailyWarBadges.tierIdForDays(6), 'recruit');
      expect(DailyWarBadges.tierIdForDays(7), 'cadet');
      expect(DailyWarBadges.tierIdForDays(13), 'officer');
      expect(DailyWarBadges.tierIdForDays(19), 'commander');
      expect(DailyWarBadges.tierIdForDays(25), 'marshal');
      expect(DailyWarBadges.tierIdForDays(40), 'marshal');
    });

    test('roman grades inside a band', () {
      expect(DailyWarBadges.titleForDays(1), 'Recruit I');
      expect(DailyWarBadges.titleForDays(3), 'Recruit II');
      expect(DailyWarBadges.titleForDays(5), 'Recruit III');
      expect(DailyWarBadges.titleForDays(6), 'Recruit IV');
      expect(DailyWarBadges.titleForDays(22), 'Commander II');
    });

    test('demote falls one tier', () {
      expect(DailyWarBadges.demoteStreakDays(15), 12); // Officer → Cadet IV
      expect(DailyWarBadges.demoteStreakDays(7), 6); // Cadet → Recruit IV
      expect(DailyWarBadges.demoteStreakDays(3), 0); // Recruit → none
    });

    test('night awards include podium and clean sweep', () {
      final awards = DailyWarBadges.nightAwards(
        air: 1,
        correct: 15,
        wrong: 0,
        unanswered: 0,
        elapsedMs: 300000,
        streakDays: 8,
        questionCount: 15,
      );
      expect(awards, contains('rank_1_champion'));
      expect(awards, contains('clean_sweep'));
      expect(awards, contains('streak_7_nights'));
    });

    test('effort awards cover week opener, finisher, century', () {
      final first = DailyWarBadges.effortAwards(
        tonightAttempted: 10,
        priorWeekAttempted: 0,
        priorWeekNights: 0,
        isFirstOfWeek: true,
        missedPreviousWarNight: false,
      );
      expect(first, containsAll(['effort_finisher', 'effort_first_war']));
      expect(first, isNot(contains('effort_back_in')));

      final century = DailyWarBadges.effortAwards(
        tonightAttempted: 25,
        priorWeekAttempted: 75,
        priorWeekNights: 5,
        isFirstOfWeek: false,
        missedPreviousWarNight: true,
      );
      expect(
        century,
        containsAll([
          'effort_finisher',
          'effort_back_in',
          'effort_full_week',
          'effort_half_century',
          'effort_century',
        ]),
      );
    });
  });
}
