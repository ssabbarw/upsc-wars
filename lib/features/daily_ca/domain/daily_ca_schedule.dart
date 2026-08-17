/// IST scheduling rules for daily current-affairs tests.
///
/// A day's questions open the **next** morning at [openHourIst]: the newspaper
/// read on the 17th carries the 16th's news, so the 16th's paper is what an
/// aspirant can be quizzed on over their morning tea on the 17th.
///
/// Content days are Mon–Sat ([isTestDay]), so Sunday has no paper and Monday
/// morning re-serves Saturday's — see [paperQuizContentDate].
abstract final class DailyCaSchedule {
  DailyCaSchedule._();

  /// Hour (IST) when the previous day's paper quiz opens.
  static const openHourIst = 6;

  static const istOffset = Duration(hours: 5, minutes: 30);

  /// Fallback when Remote Config is unavailable or invalid.
  static final DateTime defaultCalendarMinDate = DateTime(2026, 6, 5);

  static String get defaultCalendarMinDateIso =>
      formatIsoDate(defaultCalendarMinDate);

  static final _isoDatePattern = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

  /// Parses `YYYY-MM-DD` from Remote Config; falls back to [defaultCalendarMinDate].
  static DateTime parseCalendarMinDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return defaultCalendarMinDate;

    final match = _isoDatePattern.firstMatch(trimmed);
    if (match == null) return defaultCalendarMinDate;

    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static DateTime nowIst([DateTime? utcNow]) {
    final utc = (utcNow ?? DateTime.now()).toUtc();
    return utc.add(istOffset);
  }

  static DateTime dateOnly(DateTime ist) =>
      DateTime(ist.year, ist.month, ist.day);

  static bool isSunday(DateTime istDate) => istDate.weekday == DateTime.sunday;

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

  /// Newest content day whose quiz is open — the "paper" to serve right now.
  ///
  /// Skips Sundays, so Monday morning still serves Saturday's paper rather than
  /// showing nothing. Returns null only when no content day has opened yet.
  static DateTime? paperQuizContentDate({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    var cursor = dateOnly(now).subtract(const Duration(days: 1));
    for (var i = 0; i < 9; i++) {
      if (isTestDay(cursor) && isPublishedForDate(cursor, referenceIst: now)) {
        return cursor;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return null;
  }

  /// True when [contentDate] is the paper an aspirant reads on [referenceIst].
  static bool isTodaysPaper(DateTime contentDate, {DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    return dateOnly(now).difference(dateOnly(contentDate)).inDays == 1;
  }

  /// Next moment a fresh paper quiz opens (skips the Monday gap).
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
}
