class PrelimsCountdown {
  PrelimsCountdown._();

  // Update this when UPSC publishes the next prelims date.
  static final DateTime prelimsDate = DateTime(2026, 5, 24);

  static const List<String> _quotes = [
    'Discipline beats motivation.',
    'Small daily gains win big exams.',
    'Consistency today, confidence tomorrow.',
    'One focused session at a time.',
    'Show up daily. Results follow.',
    'Calm mind, sharp attempt.',
    'Progress compounds every day.',
  ];

  static int daysLeft({DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = prelimsDate.difference(current);
    if (diff.inSeconds <= 0) return 0;
    final fullDays = diff.inDays;
    final hasRemainder = diff - Duration(days: fullDays) > Duration.zero;
    return hasRemainder ? fullDays + 1 : fullDays;
  }

  static String daysLabel({DateTime? now}) {
    final days = daysLeft(now: now);
    if (days == 0) return 'Prelims is today';
    return '$days days to UPSC Prelims';
  }

  static String quoteForDate({DateTime? now}) {
    final current = now ?? DateTime.now();
    final dayOfYear = current.difference(DateTime(current.year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }
}
