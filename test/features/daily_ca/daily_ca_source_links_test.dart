import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_source_links.dart';

void main() {
  test('source URLs match the Python pipeline patterns', () {
    final links = DailyCaSourceLinks.forDate(DateTime(2026, 8, 6));
    expect(
      links[0].title,
      'InsightsIAS daily current affairs: 6 Aug',
    );
    expect(
      links[0].url,
      'https://www.insightsonindia.com/2026/08/06/'
      'upsc-current-affairs-6-august-2026/',
    );
    expect(
      links[1].url,
      'https://pwonlyias.com/news-headline/'
      'news-of-the-day-06th-august-2026/',
    );
    expect(
      links[2].url,
      'https://forumias.com/blog/'
      'must-read-news-daily-current-affairs-articles-6-august-2026/',
    );
  });

  test('ordinals match Python (11th, 21st, 23rd)', () {
    final eleventh = DailyCaSourceLinks.forDate(DateTime(2026, 8, 11));
    expect(eleventh[1].url.contains('11th-august'), isTrue);
    final twentyFirst = DailyCaSourceLinks.forDate(DateTime(2026, 8, 21));
    expect(twentyFirst[1].url.contains('21st-august'), isTrue);
    final twentyThird = DailyCaSourceLinks.forDate(DateTime(2026, 8, 23));
    expect(twentyThird[1].url.contains('23rd-august'), isTrue);
  });
}
