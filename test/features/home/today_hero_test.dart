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
    test('6 AM – 6 PM is the paper while it is still open', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 6),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.current,
      );
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 12),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.current,
      );
    });

    test('6 PM – midnight is War', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 18),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.war,
      );
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 22),
          warUrgency: TodayWarUrgency.results,
        ),
        TodaySlotId.war,
      );
    });

    test('a live War does not steal the morning paper', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 9),
          warUrgency: TodayWarUrgency.live,
        ),
        TodaySlotId.current,
      );
    });
  });

  group('TodayHero.pick', () {
    test('morning attempted but not revised stays on CA', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
      );
      expect(pick.hero, TodaySlotId.current);
      expect(pick.caughtUp, isFalse);
    });

    test('morning paper revised promotes the drill', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
        paperRevised: true,
      );
      expect(pick.hero, TodaySlotId.practice);
      expect(pick.caughtUp, isFalse);
    });

    test('morning revised and empty queue falls through to War', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
        paperRevised: true,
        revisionQueueEmpty: true,
      );
      expect(pick.hero, TodaySlotId.war);
    });

    test('noon unfinished CA stays on the paper', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 13),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(),
      );
      expect(pick.hero, TodaySlotId.current);
    });

    test('noon revised with a queue is the drill', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 13),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
        paperRevised: true,
      );
      expect(pick.hero, TodaySlotId.practice);
    });

    test('afternoon empty queue falls through to War', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 15),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
        paperRevised: true,
        revisionQueueEmpty: true,
      );
      expect(pick.hero, TodaySlotId.war);
    });

    test('6 PM – midnight is War even if the paper is still open', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 19),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(),
      );
      expect(pick.hero, TodaySlotId.war);
      expect(TodayHero.displayOrder(pick.hero, warEvening: true), [
        TodaySlotId.war,
        TodaySlotId.practice,
        TodaySlotId.current,
      ]);
    });

    test('10 PM is War even if CA was never attempted', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 22),
        warUrgency: TodayWarUrgency.results,
        slots: _slots(practiceDone: true, warDone: true),
      );
      expect(pick.hero, TodaySlotId.war);
    });

    test('overnight unfinished CA is catch-up', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 18, 1),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(practiceDone: true, warDone: true),
      );
      expect(pick.hero, TodaySlotId.current);
      expect(pick.caughtUp, isFalse);
    });

    test('overnight missing drill shows the queue, not tomorrow', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 18, 1),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true, warDone: true),
        paperRevised: true,
      );
      expect(pick.hero, TodaySlotId.practice);
      expect(pick.caughtUp, isFalse);
    });

    test('overnight all-done is last night\'s War, caught up', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 18, 1),
        warUrgency: TodayWarUrgency.results,
        slots: _slots(currentDone: true, practiceDone: true, warDone: true),
        paperRevised: true,
        revisionQueueEmpty: true,
      );
      expect(pick.hero, TodaySlotId.war);
      expect(pick.caughtUp, isTrue);
    });

    test('uses last night\'s War before 6 AM, not tomorrow\'s paper', () {
      expect(TodayHero.usesYesterdayWar(DateTime(2026, 8, 18, 1)), isTrue);
      expect(TodayHero.usesYesterdayWar(DateTime(2026, 8, 17, 22)), isFalse);
      expect(TodayHero.usesYesterdayWar(DateTime(2026, 8, 17, 6)), isFalse);
    });

    test('Sunday morning paper, then week review via the war slot', () {
      expect(
        TodayHero.pick(
          istNow: DateTime(2026, 8, 16, 8),
          warUrgency: TodayWarUrgency.none,
          slots: _slots(),
          isSunday: true,
        ).hero,
        TodaySlotId.current,
      );
      expect(
        TodayHero.pick(
          istNow: DateTime(2026, 8, 16, 8),
          warUrgency: TodayWarUrgency.none,
          slots: _slots(currentDone: true),
          isSunday: true,
          paperRevised: true,
          revisionQueueEmpty: true,
        ).hero,
        TodaySlotId.war,
      );
    });

    test('Sunday evening is Week Review (war slot)', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 16, 19),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(),
        isSunday: true,
      );
      expect(pick.hero, TodaySlotId.war);
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
      expect(TodayHero.companions(TodaySlotId.war, warEvening: true), [
        TodaySlotId.practice,
        TodaySlotId.current,
      ]);
    });

    test('Monday before 6 AM is still Sunday\'s hub', () {
      expect(TodayHero.isSundayHub(DateTime(2026, 8, 17, 1)), isTrue);
    });
  });

  group('TodayHero.forcedHero', () {
    test('practice pin wins in the morning even if CA is unfinished', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(),
        forcedHero: TodaySlotId.practice,
      );
      expect(pick.hero, TodaySlotId.practice);
    });

    test('CA pin wins after 6 PM unless War is live', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 19),
        warUrgency: TodayWarUrgency.prepare,
        slots: _slots(),
        forcedHero: TodaySlotId.current,
      );
      expect(pick.hero, TodaySlotId.current);
    });

    test('live War beats a stale CA or practice pin', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 21),
        warUrgency: TodayWarUrgency.live,
        slots: _slots(),
        forcedHero: TodaySlotId.practice,
      );
      expect(pick.hero, TodaySlotId.war);
    });

    test('rest forced slot falls through via prefer', () {
      final pick = TodayHero.pick(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(practiceAvailable: false),
        forcedHero: TodaySlotId.practice,
      );
      expect(pick.hero, TodaySlotId.current);
    });
  });

  group('TodayHero.homeLocation', () {
    test('parses and builds /?hero=', () {
      expect(TodayHero.slotIdFromQuery('practice'), TodaySlotId.practice);
      expect(TodayHero.slotIdFromQuery('current'), TodaySlotId.current);
      expect(TodayHero.slotIdFromQuery('war'), TodaySlotId.war);
      expect(TodayHero.slotIdFromQuery('nope'), isNull);
      expect(
        TodayHero.homeLocation(hero: TodaySlotId.practice),
        '/?hero=practice',
      );
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
