import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_phase.dart';
import 'package:upsc_wars/features/daily_war/providers/daily_war_providers.dart';

/// The hub hero hands the screen over to tonight's War through the evening,
/// then comes back once tonight has ranks of its own.
void main() {
  const yesterday = '2026-08-28';
  const today = '2026-08-29';

  String? heroDateId({required DailyWarPhase phase, required DateTime ist}) {
    final container = ProviderContainer(
      overrides: [
        dailyWarYesterdayDateIdProvider.overrideWithValue(yesterday),
        dailyWarHomeSnapshotProvider.overrideWithValue(
          DailyWarHomeSnapshot(dateId: today, phase: phase, istNow: ist),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(dailyWarHubHeroDateIdProvider);
  }

  test('last night holds the hero through the working day', () {
    expect(
      heroDateId(
        phase: DailyWarPhase.morning,
        ist: DateTime(2026, 8, 29, 10),
      ),
      yesterday,
    );
    expect(
      heroDateId(
        phase: DailyWarPhase.countdown,
        ist: DateTime(2026, 8, 29, 17, 59),
      ),
      yesterday,
    );
  });

  test('the hero steps aside from 6 PM so the screen is about tonight', () {
    for (final phase in [
      DailyWarPhase.countdown,
      DailyWarPhase.lobby,
      DailyWarPhase.liveJoinable,
      DailyWarPhase.liveLocked,
      DailyWarPhase.resultsPending,
    ]) {
      expect(
        heroDateId(phase: phase, ist: DateTime(2026, 8, 29, 20, 30)),
        isNull,
        reason: 'phase ${phase.name} should leave the slot to tonight',
      );
    }
  });

  test('tonight takes the hero as soon as its ranks publish', () {
    expect(
      heroDateId(
        phase: DailyWarPhase.resultsReady,
        ist: DateTime(2026, 8, 29, 21, 45),
      ),
      today,
    );
  });

  test('a Sunday evening shows no board at all', () {
    expect(
      heroDateId(
        phase: DailyWarPhase.restDay,
        ist: DateTime(2026, 8, 30, 19),
      ),
      isNull,
    );
    // ...but Saturday's Grand War still leads the Sunday daytime.
    expect(
      heroDateId(
        phase: DailyWarPhase.restDay,
        ist: DateTime(2026, 8, 30, 11),
      ),
      yesterday,
    );
  });
}
