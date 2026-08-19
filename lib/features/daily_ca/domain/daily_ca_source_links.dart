import 'package:intl/intl.dart';

/// Coaching briefs the Daily CA pipeline reads to set each day's paper.
///
/// Mirrors `daily-current-mcqs/config/url_patterns.json` + `url_builder.py`.
class DailyCaSourceLink {
  const DailyCaSourceLink({
    required this.name,
    required this.url,
    required this.title,
  });

  final String name;
  final String url;

  /// e.g. `InsightsIAS daily current affairs: 18 Aug`
  final String title;
}

abstract final class DailyCaSourceLinks {
  DailyCaSourceLinks._();

  static const _monthNames = <String>[
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];

  /// Source briefs for the news dated [contentDate] (the calendar day).
  static List<DailyCaSourceLink> forDate(DateTime contentDate) {
    final year = contentDate.year;
    final month = contentDate.month.toString().padLeft(2, '0');
    final day = contentDate.day;
    final dayPadded = day.toString().padLeft(2, '0');
    final monthName = _monthNames[contentDate.month - 1];
    final ordinal = _ordinal(day);
    final dateLabel = DateFormat('d MMM').format(contentDate);

    String titled(String name) => '$name daily current affairs: $dateLabel';

    return [
      DailyCaSourceLink(
        name: 'InsightsIAS',
        title: titled('InsightsIAS'),
        url:
            'https://www.insightsonindia.com/$year/$month/$dayPadded/'
            'upsc-current-affairs-$day-$monthName-$year/',
      ),
      DailyCaSourceLink(
        name: 'PW OnlyIAS',
        title: titled('PW OnlyIAS'),
        url:
            'https://pwonlyias.com/news-headline/'
            'news-of-the-day-$ordinal-$monthName-$year/',
      ),
      DailyCaSourceLink(
        name: 'ForumIAS',
        title: titled('ForumIAS'),
        url:
            'https://forumias.com/blog/'
            'must-read-news-daily-current-affairs-articles-'
            '$day-$monthName-$year/',
      ),
    ];
  }

  /// `1 → 01st`, `6 → 06th`, `11 → 11th` — same as the Python pipeline.
  static String _ordinal(int day) {
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : const ['th', 'st', 'nd', 'rd', 'th'][day % 10 > 4 ? 4 : day % 10];
    return '${day.toString().padLeft(2, '0')}$suffix';
  }
}
