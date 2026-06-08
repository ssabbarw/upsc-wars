/// IST scheduling rules for daily current-affairs tests.
abstract final class DailyCaSchedule {
  DailyCaSchedule._();

  static const publishHourIst = 21;
  static const istOffset = Duration(hours: 5, minutes: 30);

  /// Earliest date selectable on the daily CA calendar (IST, date-only).
  static final DateTime calendarMinDate = DateTime(2026, 6, 5);

  static String get calendarMinDateIso => formatIsoDate(calendarMinDate);

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

  static DateTime publishAtForDate(DateTime istDate) {
    final day = dateOnly(istDate);
    return DateTime(day.year, day.month, day.day, publishHourIst);
  }

  /// Whether the test for [istDate] is live (Mon–Sat, on/after 9 PM IST that day).
  static bool isPublishedForDate(DateTime istDate, {DateTime? referenceIst}) {
    if (!isTestDay(istDate)) return false;
    final now = referenceIst ?? nowIst();
    final target = dateOnly(istDate);
    final today = dateOnly(now);
    if (target.isBefore(today)) return true;
    if (target.isAfter(today)) return false;
    return !now.isBefore(publishAtForDate(istDate));
  }

  /// Next Mon–Sat 9 PM IST at or after [referenceIst].
  static DateTime nextPublishAt({DateTime? referenceIst}) {
    var cursor = referenceIst ?? nowIst();
    for (var i = 0; i < 14; i++) {
      if (isTestDay(cursor)) {
        final publishAt = publishAtForDate(cursor);
        if (!cursor.isBefore(publishAt)) {
          cursor = dateOnly(cursor).add(const Duration(days: 1));
          continue;
        }
        return publishAt;
      }
      cursor = dateOnly(cursor).add(const Duration(days: 1));
    }
    return publishAtForDate(cursor);
  }

  static Duration timeUntilNextPublish({DateTime? referenceIst}) {
    final now = referenceIst ?? nowIst();
    final next = nextPublishAt(referenceIst: now);
    final diff = next.difference(now);
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
