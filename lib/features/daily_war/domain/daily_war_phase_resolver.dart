import 'daily_war_phase.dart';
import 'daily_war_schedule.dart';

/// Derives [DailyWarPhase] from corrected IST time and optional doc status.
abstract final class DailyWarPhaseResolver {
  DailyWarPhaseResolver._();

  /// Afternoon countdown emphasis starts at this hour IST.
  static const countdownHourIst = 16;

  /// Hour (IST) the hub stops leading with the previous night's board.
  ///
  /// Evening traffic is here for tonight's paper, not last night's podium, so
  /// the hero slot hands the screen over to tonight's War from here until
  /// tonight has ranks of its own.
  static const hubHeroHandoverHourIst = 18;

  static DailyWarPhase resolve({
    required DateTime referenceIst,
    String? firestoreStatus,
    bool ranksReady = false,
    int? questionCount,
  }) {
    final warDate = DailyWarSchedule.warDateFor(referenceIst);

    if (DailyWarSchedule.isWarOffDay(warDate)) {
      return DailyWarPhase.restDay;
    }

    final announceAt = DateTime(
      warDate.year,
      warDate.month,
      warDate.day,
      DailyWarSchedule.announceHourIst,
    );
    final start = DailyWarSchedule.startAtForDate(warDate);
    final lobby = DailyWarSchedule.lobbyOpensAt(warDate);
    final lateJoin = DailyWarSchedule.lateJoinClosesAt(warDate);
    final liveEnd = DailyWarSchedule.liveEndsAt(
      warDate,
      questionCount: questionCount ??
          DailyWarSchedule.questionCountForDate(warDate),
    );

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
