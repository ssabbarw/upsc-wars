import 'daily_war_phase.dart';
import 'daily_war_schedule.dart';

/// Derives [DailyWarPhase] from corrected IST time and optional doc status.
abstract final class DailyWarPhaseResolver {
  DailyWarPhaseResolver._();

  /// Afternoon countdown emphasis starts at this hour IST.
  static const countdownHourIst = 16;

  static DailyWarPhase resolve({
    required DateTime referenceIst,
    String? firestoreStatus,
    bool ranksReady = false,
  }) {
    final warDate = DailyWarSchedule.warDateFor(referenceIst);
    final announceAt = DateTime(
      warDate.year,
      warDate.month,
      warDate.day,
      DailyWarSchedule.announceHourIst,
    );
    final start = DailyWarSchedule.startAtForDate(warDate);
    final lobby = DailyWarSchedule.lobbyOpensAt(warDate);
    final lateJoin = DailyWarSchedule.lateJoinClosesAt(warDate);
    final liveEnd = DailyWarSchedule.liveEndsAt(warDate);

    if (referenceIst.isBefore(announceAt)) {
      return DailyWarPhase.preAnnounce;
    }

    if (referenceIst.isBefore(lobby)) {
      if (referenceIst.hour >= countdownHourIst) {
        return DailyWarPhase.countdown;
      }
      return DailyWarPhase.morning;
    }

    if (referenceIst.isBefore(start)) {
      return DailyWarPhase.lobby;
    }

    if (referenceIst.isBefore(lateJoin)) {
      return DailyWarPhase.liveJoinable;
    }

    if (referenceIst.isBefore(liveEnd)) {
      return DailyWarPhase.liveLocked;
    }

    if (ranksReady || firestoreStatus == 'ranked') {
      return DailyWarPhase.resultsReady;
    }

    return DailyWarPhase.resultsPending;
  }
}
