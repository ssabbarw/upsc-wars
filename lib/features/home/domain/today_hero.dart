import '../../daily_war/domain/daily_war_phase.dart';

/// The three daily widgets on home. One is the hero; the other two stay visible.
enum TodaySlotId {
  /// Previous day's newspaper MCQs.
  current,

  /// Revision of misses / bookmarks (weekdays) or last week's mistakes (Sunday).
  practice,

  /// Tonight's Daily War.
  war,
}

enum TodaySlotStatus {
  open,
  done,
  rest,
}

enum TodayWarUrgency {
  none,
  prepare,
  live,
  results,
}

class TodaySlot {
  const TodaySlot({required this.id, required this.status});

  final TodaySlotId id;
  final TodaySlotStatus status;

  bool get isDone => status == TodaySlotStatus.done;
  bool get isOpen => status == TodaySlotStatus.open;
  bool get isRest => status == TodaySlotStatus.rest;
}

class TodayHeroPick {
  const TodayHeroPick({required this.hero, this.caughtUp = false});

  final TodaySlotId hero;
  final bool caughtUp;
}

/// Time-of-day hero plus overnight catch-up.
///
/// The hub day stays on yesterday until 6 AM so midnight does not reset the
/// three loops. Next day's War paper is generated at 5:50 AM, so overnight
/// never promotes tomorrow's drill.
abstract final class TodayHero {
  TodayHero._();

  static const paperHourIst = 6;
  static const practiceHourIst = 12;
  static const warHourIst = 18;
  static const warWindowEndHourIst = 21;

  /// Calendar day the three loops belong to (yesterday before 6 AM).
  static DateTime hubDate(DateTime istNow) {
    final day = DateTime(istNow.year, istNow.month, istNow.day);
    if (istNow.hour < paperHourIst) {
      return day.subtract(const Duration(days: 1));
    }
    return day;
  }

  /// Inclusive start of the hub day (6 AM IST of [hubDate]).
  static DateTime hubWindowStart(DateTime istNow) {
    final hub = hubDate(istNow);
    return DateTime(hub.year, hub.month, hub.day, paperHourIst);
  }

  /// Exclusive end of the hub day (next 6 AM IST).
  static DateTime hubWindowEnd(DateTime istNow) =>
      hubWindowStart(istNow).add(const Duration(days: 1));

  static bool isSundayHub(DateTime istNow) =>
      hubDate(istNow).weekday == DateTime.sunday;

  /// Midnight–6 AM: last night's War, not the paper generated at 5:50 AM.
  static bool usesYesterdayWar(DateTime istNow) => istNow.hour < paperHourIst;

  /// After 9 PM through 6 AM — War is over or the night is winding down.
  static bool afterWarUntilMorning(DateTime istNow) =>
      istNow.hour >= warWindowEndHourIst || istNow.hour < paperHourIst;

  static TodaySlotStatus _statusFor({
    required bool available,
    required bool done,
  }) {
    if (!available) return TodaySlotStatus.rest;
    return done ? TodaySlotStatus.done : TodaySlotStatus.open;
  }

  static List<TodaySlot> slotsFrom({
    required bool currentAvailable,
    required bool currentDone,
    required bool practiceAvailable,
    required bool practiceDone,
    required bool warAvailable,
    required bool warDone,
  }) {
    return [
      TodaySlot(
        id: TodaySlotId.current,
        status: _statusFor(available: currentAvailable, done: currentDone),
      ),
      TodaySlot(
        id: TodaySlotId.practice,
        status: _statusFor(available: practiceAvailable, done: practiceDone),
      ),
      TodaySlot(
        id: TodaySlotId.war,
        status: _statusFor(available: warAvailable, done: warDone),
      ),
    ];
  }

  static TodayWarUrgency warUrgencyFor(DailyWarPhase phase) {
    switch (phase) {
      case DailyWarPhase.lobby:
      case DailyWarPhase.liveJoinable:
      case DailyWarPhase.liveLocked:
        return TodayWarUrgency.live;
      case DailyWarPhase.resultsPending:
      case DailyWarPhase.resultsReady:
        return TodayWarUrgency.results;
      case DailyWarPhase.countdown:
        return TodayWarUrgency.prepare;
      case DailyWarPhase.restDay:
      case DailyWarPhase.preAnnounce:
      case DailyWarPhase.morning:
        return TodayWarUrgency.none;
    }
  }

  static TodaySlotStatus statusOf(List<TodaySlot> slots, TodaySlotId id) {
    for (final s in slots) {
      if (s.id == id) return s.status;
    }
    return TodaySlotStatus.rest;
  }

  static int availableCount(List<TodaySlot> slots) =>
      slots.where((s) => !s.isRest).length;

  static int closedCount(List<TodaySlot> slots) =>
      slots.where((s) => s.isDone).length;

  static bool isFullDay(List<TodaySlot> slots) {
    final available = availableCount(slots);
    return available > 0 && closedCount(slots) == available;
  }

  static TodaySlotId scheduledHero({
    required DateTime istNow,
    required TodayWarUrgency warUrgency,
    bool isSunday = false,
  }) {
    return pick(
      istNow: istNow,
      warUrgency: warUrgency,
      slots: slotsFrom(
        currentAvailable: true,
        currentDone: false,
        practiceAvailable: true,
        practiceDone: false,
        warAvailable: !isSunday,
        warDone: false,
      ),
      isSunday: isSunday,
    ).hero;
  }

  static TodaySlotId heroFor({
    required DateTime istNow,
    required TodayWarUrgency warUrgency,
    required List<TodaySlot> slots,
    bool isSunday = false,
  }) {
    return pick(
      istNow: istNow,
      warUrgency: warUrgency,
      slots: slots,
      isSunday: isSunday,
    ).hero;
  }

  static TodayHeroPick pick({
    required DateTime istNow,
    required TodayWarUrgency warUrgency,
    required List<TodaySlot> slots,
    bool isSunday = false,
  }) {
    TodayHeroPick prefer(TodaySlotId id, {bool caughtUp = false}) {
      bool available(TodaySlotId x) =>
          statusOf(slots, x) != TodaySlotStatus.rest;
      List<TodaySlotId> nearby(TodaySlotId from) {
        switch (from) {
          case TodaySlotId.current:
            return const [TodaySlotId.practice, TodaySlotId.war];
          case TodaySlotId.practice:
            return const [TodaySlotId.current, TodaySlotId.war];
          case TodaySlotId.war:
            return const [TodaySlotId.practice, TodaySlotId.current];
        }
      }

      if (available(id)) return TodayHeroPick(hero: id, caughtUp: caughtUp);
      for (final x in nearby(id)) {
        if (statusOf(slots, x) == TodaySlotStatus.open) {
          return TodayHeroPick(hero: x, caughtUp: caughtUp);
        }
      }
      for (final x in nearby(id)) {
        if (available(x)) return TodayHeroPick(hero: x, caughtUp: caughtUp);
      }
      return TodayHeroPick(hero: id, caughtUp: caughtUp);
    }

    if (warUrgency == TodayWarUrgency.live &&
        statusOf(slots, TodaySlotId.war) != TodaySlotStatus.rest) {
      return const TodayHeroPick(hero: TodaySlotId.war);
    }

    final hour = istNow.hour;
    final caOpen = statusOf(slots, TodaySlotId.current) == TodaySlotStatus.open;
    final drillOpen =
        statusOf(slots, TodaySlotId.practice) == TodaySlotStatus.open;
    final warOpen = statusOf(slots, TodaySlotId.war) == TodaySlotStatus.open;

    TodayHeroPick overnightCatchUp() {
      if (isFullDay(slots)) {
        return prefer(
          isSunday ? TodaySlotId.practice : TodaySlotId.war,
          caughtUp: true,
        );
      }
      if (caOpen) return prefer(TodaySlotId.current);
      if (drillOpen) return prefer(TodaySlotId.practice);
      if (warOpen) return prefer(TodaySlotId.war);
      return prefer(
        isSunday ? TodaySlotId.practice : TodaySlotId.war,
        caughtUp: true,
      );
    }

    if (afterWarUntilMorning(istNow)) {
      return overnightCatchUp();
    }

    if (isSunday) {
      if (hour >= practiceHourIst) {
        return prefer(TodaySlotId.practice);
      }
      if (caOpen) return prefer(TodaySlotId.current);
      return prefer(TodaySlotId.practice);
    }

    // 6 PM – 9 PM: wait for War; drill stays visible as a companion.
    if (hour >= warHourIst && hour < warWindowEndHourIst) {
      return prefer(TodaySlotId.war);
    }

    // Noon – 6 PM: War-topic drill.
    if (hour >= practiceHourIst && hour < warHourIst) {
      return prefer(TodaySlotId.practice);
    }

    // 6 AM – noon: paper, then drill once the paper is done.
    if (caOpen) return prefer(TodaySlotId.current);
    return prefer(TodaySlotId.practice);
  }

  static List<TodaySlotId> displayOrder(
    TodaySlotId hero, {
    bool warEvening = false,
    bool caughtUp = false,
  }) {
    if (caughtUp) {
      return const [
        TodaySlotId.current,
        TodaySlotId.practice,
        TodaySlotId.war,
      ];
    }
    if (warEvening && hero == TodaySlotId.war) {
      return const [
        TodaySlotId.war,
        TodaySlotId.practice,
        TodaySlotId.current,
      ];
    }
    const rest = [TodaySlotId.current, TodaySlotId.practice, TodaySlotId.war];
    return [hero, ...rest.where((id) => id != hero)];
  }

  /// Non-hero loops, in the order they should sit in the companion row.
  static List<TodaySlotId> companions(
    TodaySlotId hero, {
    bool warEvening = false,
  }) {
    final ordered = displayOrder(hero, warEvening: warEvening);
    return [for (final id in ordered) if (id != hero) id];
  }
}
