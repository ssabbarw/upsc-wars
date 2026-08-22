import 'package:flutter/foundation.dart';

import '../../daily_war/domain/daily_war_schedule.dart';
import '../domain/today_hero.dart';

/// In-memory pin: show this Today-hub slot as the hero for the rest of the
/// hub day (or until that slot completes).
class TodayHeroIntent {
  const TodayHeroIntent({required this.slot, required this.hubDate});

  final TodaySlotId slot;
  final DateTime hubDate;
}

/// Written from notification taps (no [Ref]) and read by the home hub.
abstract final class TodayHeroIntentStore {
  TodayHeroIntentStore._();

  static final ValueNotifier<TodayHeroIntent?> notifier = ValueNotifier(null);

  static TodayHeroIntent? get current => notifier.value;

  static void capture(TodaySlotId slot, {DateTime? istNow}) {
    final now = istNow ?? DailyWarSchedule.nowIst();
    notifier.value = TodayHeroIntent(
      slot: slot,
      hubDate: TodayHero.hubDate(now),
    );
  }

  static void clear() {
    if (notifier.value == null) return;
    notifier.value = null;
  }

  @visibleForTesting
  static void reset() => clear();
}
