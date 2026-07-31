/// IST schedule for Daily War / Grand War.
///
/// Live window length is derived from tonight's question count
/// ([secondsPerQuestion] each), not a fixed minute constant.
/// Start remains 9:00 PM IST for every night.
///
/// Use [nowIst] with an optional corrected UTC instant from the server-clock
/// offset provider — never rely on device local timezone for phase gates.
abstract final class DailyWarSchedule {
  DailyWarSchedule._();

  static const istOffset = Duration(hours: 5, minutes: 30);

  /// Topic announcement is considered "morning" from this hour IST.
  static const announceHourIst = 6;

  /// Lobby opens this many minutes before [startHourIst].
  static const lobbyLeadMinutes = 15;

  static const startHourIst = 21;
  static const startMinuteIst = 0;

  /// Late join allowed until this many minutes after start.
  static const lateJoinMinutes = 10;

  /// Pace used to size the shared live window from question count.
  /// 15 Q → 20 min · 25 Q → 34 min (ceil).
  static const secondsPerQuestion = 80;

  /// Minutes after [liveEndsAt] when ranks are expected.
  static const rankPublishBufferMinutes = 5;

  static const weekdayQuestionCount = 15;
  static const grandWarQuestionCount = 25;

  /// Minimum participants before UI shows raw lobby/count numbers.
  static const minVisibleParticipantCount = 200;

  /// Shared live-window length for a paper of [questionCount] questions.
  static int liveWindowMinutesFor(int questionCount) {
    final q = questionCount < 1 ? weekdayQuestionCount : questionCount;
    final minutes = (q * secondsPerQuestion / 60).ceil();
    return minutes.clamp(1, 120);
  }

  static DateTime nowIst([DateTime? utcNow]) {
    final utc = (utcNow ?? DateTime.now()).toUtc();
    return utc.add(istOffset);
  }

  static DateTime dateOnly(DateTime ist) =>
      DateTime(ist.year, ist.month, ist.day);

  static bool isSunday(DateTime istDate) => istDate.weekday == DateTime.sunday;

  /// Grand War runs on Sundays; Daily War Mon–Sat.
  static bool isGrandWarDay(DateTime istDate) => isSunday(istDate);

  static int questionCountForDate(DateTime istDate) =>
      isGrandWarDay(istDate) ? grandWarQuestionCount : weekdayQuestionCount;

  static String formatIsoDate(DateTime istDate) {
    final y = istDate.year.toString().padLeft(4, '0');
    final m = istDate.month.toString().padLeft(2, '0');
    final d = istDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseIsoDate(String iso) {
    final parts = iso.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime startAtForDate(DateTime istDate) {
    final day = dateOnly(istDate);
    return DateTime(
      day.year,
      day.month,
      day.day,
      startHourIst,
      startMinuteIst,
    );
  }

  static DateTime lobbyOpensAt(DateTime istDate) =>
      startAtForDate(istDate).subtract(const Duration(minutes: lobbyLeadMinutes));

  static DateTime lateJoinClosesAt(DateTime istDate) =>
      startAtForDate(istDate).add(const Duration(minutes: lateJoinMinutes));

  static DateTime liveEndsAt(DateTime istDate, {int? questionCount}) {
    final q = questionCount ?? questionCountForDate(istDate);
    return startAtForDate(istDate).add(
      Duration(minutes: liveWindowMinutesFor(q)),
    );
  }

  static DateTime rankTargetAt(DateTime istDate, {int? questionCount}) =>
      liveEndsAt(istDate, questionCount: questionCount).add(
        const Duration(minutes: rankPublishBufferMinutes),
      );

  /// e.g. `9:20 PM` for copy that previously hard-coded the close time.
  static String formatClock(DateTime ist) {
    final h24 = ist.hour;
    final m = ist.minute.toString().padLeft(2, '0');
    final suffix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    return '$h12:$m $suffix';
  }

  /// War calendar day for [referenceIst] — always today's IST date.
  /// Results for tonight stay on today's dateId until midnight; tomorrow's
  /// announcement uses [nextWarDate] after midnight (or explicit next_topics).
  static DateTime warDateFor(DateTime referenceIst) => dateOnly(referenceIst);

  static DateTime nextWarDate(DateTime referenceIst) =>
      dateOnly(referenceIst).add(const Duration(days: 1));

  static String formatCountdown(Duration remaining) {
    if (remaining.inSeconds <= 0) return '00:00:00';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}
