import '../../daily_war/domain/daily_war_phase.dart';

/// The three daily widgets on home. One is the hero; the other two stay visible.
enum TodaySlotId {
  /// Previous day's newspaper MCQs.
  current,

  /// Static syllabus drill on weekdays; last week's mistakes on Sunday.
  practice,

  /// Tonight's Daily War.
  war,
}

enum TodaySlotStatus {
  /// Available and not yet done.
  open,

  /// Done today.
  done,

  /// Nothing to do today (Sunday War, no paper, feature off).
  rest,
}

/// How strong a claim War has on the hero slot beyond the 6–9 PM window.
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

/// Time-of-day hero: paper in the morning, drill in the afternoon, War at dusk.
///
/// Completion does **not** steal the slot — 9 AM still highlights the paper
/// even if it is already done — so the three widgets keep a stable meaning.
abstract final class TodayHero {
  TodayHero._();

  /// Paper quiz owns the slot from 6 AM until noon.
  static const paperHourIst = 6;

  /// Drill / mistakes from noon until 6 PM.
  static const practiceHourIst = 12;

  /// War from 6 PM until 9 PM.
  static const warHourIst = 18;

  /// End of the scheduled War window. Live/results may keep it after this.
  static const warWindowEndHourIst = 21;

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

  /// Clock window first; a live War is the only thing that cuts in.
  ///
  /// Sunday has no War, so noon onward belongs to week-review (the practice
  /// slot) instead of the 6 PM War window.
  static TodaySlotId scheduledHero({
    required DateTime istNow,
    required TodayWarUrgency warUrgency,
    bool isSunday = false,
  }) {
    if (warUrgency == TodayWarUrgency.live) return TodaySlotId.war;

    final hour = istNow.hour;
    if (isSunday) {
      if (hour >= practiceHourIst) return TodaySlotId.practice;
      return TodaySlotId.current;
    }
    if (hour >= warHourIst && hour < warWindowEndHourIst) {
      return TodaySlotId.war;
    }
    // After 9 PM the live window is still the evening's job.
    if (hour >= warWindowEndHourIst &&
        (warUrgency == TodayWarUrgency.results ||
            warUrgency == TodayWarUrgency.prepare)) {
      return TodaySlotId.war;
    }
    if (hour >= practiceHourIst && hour < warHourIst) {
      return TodaySlotId.practice;
    }
    return TodaySlotId.current;
  }

  /// Same as [scheduledHero], skipping a slot that is resting today.
  static TodaySlotId heroFor({
    required DateTime istNow,
    required TodayWarUrgency warUrgency,
    required List<TodaySlot> slots,
    bool isSunday = false,
  }) {
    final scheduled = scheduledHero(
      istNow: istNow,
      warUrgency: warUrgency,
      isSunday: isSunday,
    );
    if (statusOf(slots, scheduled) != TodaySlotStatus.rest) return scheduled;

    const fallbackByScheduled = {
      TodaySlotId.war: [TodaySlotId.practice, TodaySlotId.current],
      TodaySlotId.current: [TodaySlotId.practice, TodaySlotId.war],
      TodaySlotId.practice: [TodaySlotId.current, TodaySlotId.war],
    };
    for (final id in fallbackByScheduled[scheduled]!) {
      if (statusOf(slots, id) != TodaySlotStatus.rest) return id;
    }
    return scheduled;
  }

  /// Hero first, then paper → drill → War so the other two keep a stable order.
  static List<TodaySlotId> displayOrder(TodaySlotId hero) {
    const rest = [TodaySlotId.current, TodaySlotId.practice, TodaySlotId.war];
    return [hero, ...rest.where((id) => id != hero)];
  }
}
