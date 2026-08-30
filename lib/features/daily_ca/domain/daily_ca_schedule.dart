/// IST scheduling rules for daily current-affairs tests.
///
/// A day's questions open the **next** morning at [openHourIst]: the newspaper
/// read on the 17th carries the 16th's news, so the 16th's paper is what an
/// aspirant can be quizzed on over their morning tea on the 17th.
///
/// Content days are Mon–Sat ([isTestDay]). **Sunday has no paper.**
/// Saturday's paper opens Sunday morning — see [paperQuizContentDate].
abstract final class DailyCaSchedule {
  DailyCaSchedule._();

  /// Hour (IST) when the previous day's paper quiz opens.
  static const openHourIst = 6;

  static const istOffset = Duration(hours: 5, minutes: 30);

  /// Fallback when Remote Config is unavailable or invalid.
  /// First public Daily CA paper date — calendars never go earlier.
  static final DateTime defaultCalendarMinDate = DateTime(2026, 8, 18);

  static String get defaultCalendarMinDateIso =>
      formatIsoDate(defaultCalendarMinDate);

  static final _isoDatePattern = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

  /// Parses `YYYY-MM-DD` from Remote Config; falls back to [defaultCalendarMinDate].
  static DateTime parseCalendarMinDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return defaultCalendarMinDate;

    final match = _isoDatePattern.firstMatch(trimmed);
    if (match == null) return defaultCalendarMinDate;

    final parsed = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (parsed.isBefore(defaultCalendarMinDate)) {
      return defaultCalendarMinDate;
    }
    return parsed;
  }

  /// Current IST wall clock as a timezone-agnostic [DateTime].
  ///
  /// Do not return a UTC-tagged value: [nextOpensAt] is a local civil time,
  /// and mixing the two shortens countdowns by the IST offset (~5h).
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

  /// Sunday has no newspaper pack. Saturday is a normal test day.
  static bool isTestDay(DateTime istDate) => !isSunday(istDate);

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

  /// When [contentDate]'s questions open — the morning after, at [openHourIst].
  static DateTime opensAtForDate(DateTime contentDate) {
    final next = dateOnly(contentDate).add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, openHourIst);
  }

  /// Whether the quiz for news dated [istDate] is attemptable at [referenceIst].
  static bool isPublishedForDate(DateTime istDate, {DateTime? referenceIst}) {
    if (!isTestDay(istDate)) return false;
    final now = referenceIst ?? nowIst();
    return !now.isBefore(opensAtForDate(istDate));
  }

  /// History calendar cells that should open the day sheet.
  ///
  /// Published papers plus **today**, even on Sunday and before 6 AM, so the
  /// highlighted cell opens today's paper (yesterday's news) instead of a dead tap.
  /// Later days stay closed.
  static bool isCalendarDaySelectable(
    DateTime istDate, {
    required DateTime minDate,
    DateTime? referenceIst,
  }) {
    final now = referenceIst ?? nowIst();
    if (dateOnly(istDate) == dateOnly(now)) return true;
    if (isSunday(istDate)) return false;
    if (!isOnOrAfterMinDate(istDate, minDate)) return false;
    return isPublishedForDate(istDate, referenceIst: now);
  }

  /// News date the history calendar should show for a tap on [tappedDate].
  ///
  /// Today always maps to [expectedPaperContentDate] — the same paper as the
  /// Today's Paper card, even before it opens, so the cell still explains
  /// itself instead of swallowing the tap. Other days are themselves.
  static DateTime? calendarTapContentDate(
    DateTime tappedDate, {
    DateTime? referenceIst,
  }) {
    final now = referenceIst ?? nowIst();
    if (dateOnly(tappedDate) == dateOnly(now)) {
      return expectedPaperContentDate(referenceIst: now);
    }
    return dateOnly(tappedDate);
  }

  /// Whether [isoDate] is the currently ranked live paper (today's quiz).
  static bool isRankedLiveDate(String isoDate, {DateTime? referenceIst}) {
    final current = paperQuizContentDate(referenceIst: referenceIst);
    if (current == null) return false;
    return formatIsoDate(current) == isoDate.trim();
  }

  /// Content day the current paper is drawn from, open yet or not.
  ///
  /// Always yesterday, except that Sunday carries no newspaper pack — so
  /// Monday reaches back to Saturday. It never reaches further than that:
  /// dressing up an older paper as today's hides a day the pipeline missed,
  /// and the reader has no way to tell they are re-attempting stale news.
  static DateTime expectedPaperContentDate({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    final cursor = dateOnly(now).subtract(const Duration(days: 1));
    return isTestDay(cursor) ? cursor : cursor.subtract(const Duration(days: 1));
  }

  /// Recent newspaper-pack dates to prefetch (walks back past Sundays).
  static List<DateTime> recentTestContentDates({
    int count = 3,
    DateTime? referenceIst,
  }) {
    final now = referenceIst ?? nowIst();
    final dates = <DateTime>[];
    var cursor = dateOnly(now).subtract(const Duration(days: 1));
    for (var i = 0; i < 14 && dates.length < count; i++) {
      if (isTestDay(cursor)) dates.add(cursor);
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return dates;
  }

  /// [expectedPaperContentDate] once its quiz has opened — the paper to serve
  /// right now. Null between midnight and [openHourIst], and on any day the
  /// expected paper never opened.
  static DateTime? paperQuizContentDate({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    final expected = expectedPaperContentDate(referenceIst: now);
    return isPublishedForDate(expected, referenceIst: now) ? expected : null;
  }

  /// Paper before [expectedPaperContentDate] — the board whose champion just
  /// locked.
  ///
  /// Keeps walking back past unpublished days: an archive board is allowed to
  /// be old, unlike the paper being offered as today's.
  static DateTime? previousPaperQuizContentDate({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    var cursor = expectedPaperContentDate(
      referenceIst: now,
    ).subtract(const Duration(days: 1));
    for (var i = 0; i < 9; i++) {
      if (isTestDay(cursor) && isPublishedForDate(cursor, referenceIst: now)) {
        return cursor;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return null;
  }

  /// Calendar morning the [contentDate] paper was the live quiz (opens next day).
  static DateTime quizMorningDate(DateTime contentDate) =>
      dateOnly(opensAtForDate(contentDate));

  /// True when [contentDate] is the paper an aspirant reads on [referenceIst].
  static bool isTodaysPaper(DateTime contentDate, {DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    return dateOnly(now).difference(dateOnly(contentDate)).inDays == 1;
  }

  /// Next moment a fresh paper quiz opens (skips the Monday-morning gap).
  static DateTime nextOpensAt({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    var day = dateOnly(now);
    for (var i = 0; i < 9; i++) {
      final at = DateTime(day.year, day.month, day.day, openHourIst);
      if (now.isBefore(at) &&
          isTestDay(day.subtract(const Duration(days: 1)))) {
        return at;
      }
      day = day.add(const Duration(days: 1));
    }
    return DateTime(day.year, day.month, day.day, openHourIst);
  }

  static Duration timeUntilNextOpen({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    final diff = nextOpensAt(referenceIst: now).difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// `HH:MM` when ≥ 1 min left; otherwise `Ss` seconds.
  static String formatCountdown(Duration remaining) {
    if (remaining.inSeconds <= 0) return '00:00';
    if (remaining.inMinutes < 1) return '${remaining.inSeconds}s';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Live timer pill — always `HH:MM:SS`.
  static String formatCountdownHms(Duration remaining) {
    final d = remaining.isNegative ? Duration.zero : remaining;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String monthStartIso(int year, int month) =>
      formatIsoDate(DateTime(year, month, 1));

  static String monthEndIso(int year, int month) {
    final last = DateTime(year, month + 1, 0);
    return formatIsoDate(last);
  }

  /// Whether [istDate] is on or after [minDateInclusive] (date-only compare).
  static bool isOnOrAfterMinDate(DateTime istDate, DateTime minDateInclusive) {
    return !dateOnly(istDate).isBefore(dateOnly(minDateInclusive));
  }

  static DateTime minMonthForDate(DateTime minDate) =>
      DateTime(minDate.year, minDate.month);

  static bool isMonthBefore(int year, int month, DateTime minMonth) {
    if (year < minMonth.year) return true;
    if (year == minMonth.year && month < minMonth.month) return true;
    return false;
  }

  static bool isMonthAfter(int year, int month, DateTime maxMonth) {
    if (year > maxMonth.year) return true;
    if (year == maxMonth.year && month > maxMonth.month) return true;
    return false;
  }
}
