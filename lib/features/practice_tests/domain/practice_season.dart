/// Which prelims cycle the numbered practice tests belong to.
///
/// [year] is the year of the next prelims that has not passed yet.
/// [start] is when that cycle's coverage window opened (the previous prelims).
class PracticeSeason {
  const PracticeSeason({
    required this.year,
    required this.start,
    required this.prelimsDate,
  });

  final int year;
  final DateTime start;
  final DateTime prelimsDate;
}

/// Season year for [now] given the configured prelims instant.
///
/// On or before [prelimsDate], the season is that date's year. After it, the
/// season is the following year, until Remote Config (or the in-app default)
/// moves the date forward.
int seasonFor(DateTime prelimsDate, DateTime now) {
  if (!now.isAfter(prelimsDate)) return prelimsDate.year;
  return prelimsDate.year + 1;
}

/// Start of the coverage window for the season that [now] falls in.
DateTime seasonStart(DateTime prelimsDate, DateTime now) {
  final season = seasonFor(prelimsDate, now);
  if (season == prelimsDate.year) {
    return DateTime(
      prelimsDate.year - 1,
      prelimsDate.month,
      prelimsDate.day,
      prelimsDate.hour,
      prelimsDate.minute,
    );
  }
  return prelimsDate;
}

PracticeSeason practiceSeasonAt(DateTime prelimsDate, DateTime now) {
  return PracticeSeason(
    year: seasonFor(prelimsDate, now),
    start: seasonStart(prelimsDate, now),
    prelimsDate: prelimsDate,
  );
}
