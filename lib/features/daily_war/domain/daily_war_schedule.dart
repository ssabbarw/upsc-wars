/// IST schedule for Static War / Grand War.
///
/// Rhythm: **Mon–Fri** Daily Battle (2 topics) · **Saturday** Grand War (week
/// revision) · **Sunday** off.
///
/// Live window length is derived from tonight's question count
/// ([secondsPerQuestion] each). Start remains 9:00 PM IST on War nights.
///
/// Use [nowIst] with an optional corrected UTC instant from the server-clock
/// offset provider — never rely on device local timezone for phase gates.
abstract final class DailyWarSchedule {
  DailyWarSchedule._();

  static const istOffset = Duration(hours: 5, minutes: 30);

  /// Topic announcement is considered "morning" from this hour IST.
  static const announceHourIst = 6;

  /// Lobby opens one minute before the synchronized start.
  static const lobbyLeadMinutes = 1;

  static const startHourIst = 21;
  static const startMinuteIst = 0;

  /// Late join allowed until this many minutes after start.
  static const lateJoinMinutes = 10;

  /// Pace used to size the shared live window from question count.
  /// 15 Q → 20 min · 25 Q → 34 min (ceil).
  static const secondsPerQuestion = 80;

  /// The batch rank job publishes AIR after every possible live window closes.
  static const rankPublishHourIst = 21;
  static const rankPublishMinuteIst = 40;

  static const weekdayQuestionCount = 15;
  static const grandWarQuestionCount = 25;

  /// Minimum participants before UI shows raw lobby/count numbers.
  static const minVisibleParticipantCount = 200;

  /// First public War night — calendars never go earlier.
  static final DateTime calendarMinDate = DateTime(2026, 8, 18);

  /// Shared live-window length for a paper of [questionCount] questions.
  static int liveWindowMinutesFor(int questionCount) {
    final q = questionCount < 1 ? weekdayQuestionCount : questionCount;
    final minutes = (q * secondsPerQuestion / 60).ceil();
    return minutes.clamp(1, 120);
  }

  /// Current IST **wall clock** as a timezone-agnostic [DateTime].
  static DateTime nowIst([DateTime? utcNow]) {
    final utc = (utcNow ?? DateTime.now()).toUtc();
    final shifted = utc.add(istOffset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  static DateTime dateOnly(DateTime ist) =>
      DateTime(ist.year, ist.month, ist.day);

  static bool isSunday(DateTime istDate) => istDate.weekday == DateTime.sunday;

  static bool isSaturday(DateTime istDate) =>
      istDate.weekday == DateTime.saturday;

  /// No War on Sundays.
  static bool isWarOffDay(DateTime istDate) => isSunday(istDate);

  /// Grand War runs on Saturdays (revises Mon–Fri).
  static bool isGrandWarDay(DateTime istDate) => isSaturday(istDate);

  /// Mon–Fri Daily Battle nights.
  static bool isWeekdayWarDay(DateTime istDate) =>
      istDate.weekday >= DateTime.monday && istDate.weekday <= DateTime.friday;

  /// Any night that has a live paper (Mon–Sat).
  static bool isWarDay(DateTime istDate) =>
      isWeekdayWarDay(istDate) || isGrandWarDay(istDate);

  static int questionCountForDate(DateTime istDate) {
    if (!isWarDay(istDate)) return weekdayQuestionCount;
    return isGrandWarDay(istDate)
        ? grandWarQuestionCount
        : weekdayQuestionCount;
  }

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
    return DateTime(day.year, day.month, day.day, startHourIst, startMinuteIst);
  }

  static DateTime lobbyOpensAt(DateTime istDate) => startAtForDate(
    istDate,
  ).subtract(const Duration(minutes: lobbyLeadMinutes));

  static DateTime lateJoinClosesAt(DateTime istDate) =>
      startAtForDate(istDate).add(const Duration(minutes: lateJoinMinutes));

  static DateTime liveEndsAt(DateTime istDate, {int? questionCount}) {
    final q = questionCount ?? questionCountForDate(istDate);
    return startAtForDate(
      istDate,
    ).add(Duration(minutes: liveWindowMinutesFor(q)));
  }

  static DateTime rankTargetAt(DateTime istDate, {int? questionCount}) {
    final day = dateOnly(istDate);
    return DateTime(
      day.year,
      day.month,
      day.day,
      rankPublishHourIst,
      rankPublishMinuteIst,
    );
  }

  /// e.g. `9:20 PM` for copy that previously hard-coded the close time.
  static String formatClock(DateTime ist) {
    final h24 = ist.hour;
    final m = ist.minute.toString().padLeft(2, '0');
    final suffix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    return '$h12:$m $suffix';
  }

  /// War calendar day for [referenceIst] — today's IST date.
  static DateTime warDateFor(DateTime referenceIst) => dateOnly(referenceIst);

  /// Next calendar day that has a War (skips Sunday).
  static DateTime nextWarDate(DateTime referenceIst) {
    var d = dateOnly(referenceIst).add(const Duration(days: 1));
    while (isWarOffDay(d)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// Previous calendar day that had a War (skips Sunday).
  static DateTime previousWarDate(DateTime referenceIst) {
    var d = dateOnly(referenceIst).subtract(const Duration(days: 1));
    while (isWarOffDay(d)) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

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
