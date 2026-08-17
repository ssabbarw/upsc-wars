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
  group('TodayHero.scheduledHero', () {
    test('6 AM – noon is the paper', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 6),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.current,
      );
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 11, 59),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.current,
      );
    });

    test('noon – 6 PM is the drill', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 12),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.practice,
      );
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 17, 59),
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
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 20, 59),
          warUrgency: TodayWarUrgency.none,
        ),
        TodaySlotId.war,
      );
    });

    test('after 9 PM War stays hero while live or results are in', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 17, 21, 10),
          warUrgency: TodayWarUrgency.live,
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

  group('TodayHero.heroFor', () {
    test('stays on the paper in the morning even after it is done', () {
      final hero = TodayHero.heroFor(
        istNow: DateTime(2026, 8, 17, 8),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(currentDone: true),
      );
      expect(hero, TodaySlotId.current);
    });

    test('Sunday evening skips War rest and uses week review', () {
      final hero = TodayHero.heroFor(
        istNow: DateTime(2026, 8, 16, 19),
        warUrgency: TodayWarUrgency.none,
        slots: _slots(warAvailable: false),
        isSunday: true,
      );
      expect(hero, TodaySlotId.practice);
    });

    test('Sunday morning still belongs to the paper', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 16, 8),
          warUrgency: TodayWarUrgency.none,
          isSunday: true,
        ),
        TodaySlotId.current,
      );
    });

    test('Sunday from noon is week review, not War', () {
      expect(
        TodayHero.scheduledHero(
          istNow: DateTime(2026, 8, 16, 18, 30),
          warUrgency: TodayWarUrgency.none,
          isSunday: true,
        ),
        TodaySlotId.practice,
      );
    });

    test('hero is first, then paper → drill → War', () {
      expect(
        TodayHero.displayOrder(TodaySlotId.practice),
        [TodaySlotId.practice, TodaySlotId.current, TodaySlotId.war],
      );
    });
  });

  group('TodayHero.warUrgencyFor', () {
    test('lobby through live is the strongest claim', () {
      for (final p in [
        DailyWarPhase.lobby,
        DailyWarPhase.liveJoinable,
        DailyWarPhase.liveLocked,
      ]) {
        expect(TodayHero.warUrgencyFor(p), TodayWarUrgency.live);
      }
    });
  });
}
