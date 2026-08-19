import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_phase.dart';
import 'package:upsc_wars/features/home/domain/today_hero.dart';

List<TodaySlot> _slots({
  bool currentAvailable = true,
  bool currentDone = false,
  bool practiceAvailable = true,
  bool practiceDone = false,
  bool warAvailable = true,
  bool warDone = false,
}) {
  return TodayHero.slotsFrom(
    currentAvailable: currentAvailable,
    currentDone: currentDone,
    practiceAvailable: practiceAvailable,
    practiceDone: practiceDone,
    warAvailable: warAvailable,
    warDone: warDone,
  );
}

void main() {
  group('TodayHero.hubDate', () {
    test('before 6 AM belongs to yesterday', () {
      expect(
        TodayHero.hubDate(DateTime(2026, 8, 18, 1)),
        DateTime(2026, 8, 17),
      );
    });

    test('from 6 AM is today', () {
      expect(
        TodayHero.hubDate(DateTime(2026, 8, 17, 6)),
        DateTime(2026, 8, 17),
      );
    });

    test('hub window is 6 AM to next 6 AM', () {
      expect(
        TodayHero.hubWindowStart(DateTime(2026, 8, 18, 1)),
        DateTime(2026, 8, 17, 6),
      );
      expect(
        TodayHero.hubWindowEnd(DateTime(2026, 8, 18, 1)),
        DateTime(2026, 8, 18, 6),
      );
    });
  });

  group('TodayHero.scheduledHero', () {
    test('6 AM – noon is the paper when it is still open', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 6),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.current,
      );
    });

    test('noon – 6 PM is the revision queue', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 12),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.practice,
      );
    });

    test('6 PM – 9 PM is War', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 18),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.war,
      );
    });

    test('a live War cuts into the morning paper window', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 9),
          warUrgency: TodayWarUrgency.live,
        ),
        TodaySlotId.war,
      );
    });
  });

  group('TodayHero.pick', () {
    test('morning paper done promotes the drill', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
      );
      expect(pick.hero, TodaySlotId.practice);
      expect(pick.caughtUp, isFalse);
    });

    test('6 PM – 9 PM is War even if the paper is still open', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 19),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(),
      );
      expect(pick.hero, TodaySlotId.war);
      expect(
        TodayHero.displayOrder(
          pick.hero,
          warEvening: true,
        ),
        [
          TodaySlotId.war,
          TodaySlotId.practice,
          TodaySlotId.current,
        ],
      );
    });

    test('overnight all-done is caught up', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 22),
        warUrgency: TodayWarUrgency.results,
        slots: _slots(
          currentDone: true,
          practiceDone: true,
          warDone: true,
        ),
      );
      expect(pick.caughtUp, isTrue);
    });

    test('overnight missing paper shows current affairs', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 22),
        warUrgency: TodayWarUrgency.results,
        slots: _slots(practiceDone: true, warDone: true),
      );
      expect(pick.hero, TodaySlotId.current);
      expect(pick.caughtUp, isFalse);
    });

    test('overnight missing drill shows tonight\'s topics, not tomorrow', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 18, 1),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true, warDone: true),
      );
      expect(pick.hero, TodaySlotId.practice);
      expect(pick.caughtUp, isFalse);
    });

    test('uses last night\'s War before 6 AM, not tomorrow\'s paper', () {
      expect(TodayHero.usesYesterdayWar(DateTime(2026, 8, 18, 1)), isTrue);
      expect(TodayHero.usesYesterdayWar(DateTime(2026, 8, 17, 22)), isFalse);
      expect(TodayHero.usesYesterdayWar(DateTime(2026, 8, 17, 6)), isFalse);
    });

    test('Sunday morning paper, then week review', () {
      expect(
        TodayHero.pick(
          istNow: DateTime(2026, 8, 16, 8),
          warUrgency: TodayWarUrgency.none,
          slots: _slots(warAvailable: false),
          isSunday: true,
        ).hero,
        TodaySlotId.current,
      );
      expect(
        TodayHero.pick(
          istNow: DateTime(2026, 8, 16, 8),
          warUrgency: TodayWarUrgency.none,
          slots: _slots(currentDone: true, warAvailable: false),
          isSunday: true,
        ).hero,
        TodaySlotId.practice,
      );
    });

    test('evening with War off falls through to the drill', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 19),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(warAvailable: false),
      );
      expect(pick.hero, TodaySlotId.practice);
    });

    test('paper off in the morning promotes the drill', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentAvailable: false),
      );
      expect(pick.hero, TodaySlotId.practice);
    });

    test('companions sit beside the hero, not under a stack', () {
      expect(
        TodayHero.companions(TodaySlotId.war, warEvening: true),
        [TodaySlotId.practice, TodaySlotId.current],
      );
    });

    test('Monday before 6 AM is still Sunday\'s hub', () {
      expect(TodayHero.isSundayHub(DateTime(2026, 8, 17, 1)), isTrue);
    });
  });

  group('TodayHero.warUrgencyFor', () {
    test('lobby through live is the strongest claim', () {
      expect(
        TodayHero.warUrgencyFor(DailyWarPhase.liveJoinable),
        TodayWarUrgency.live,
      );
    });
  });
}
