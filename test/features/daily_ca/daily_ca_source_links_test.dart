import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_source_links.dart';

void main() {
  test('source URLs match InsightsIAS and ForumIAS patterns', () {
    final links = DailyCaSourceLinks.forDate(DateTime(2026, 8, 6));
    expect(links, hasLength(2));
    expect(links.map((l) => l.name), ['InsightsIAS', 'ForumIAS']);
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
      links[1].title,
      'ForumIAS daily current affairs: 6 Aug',
    );
    expect(
      links[1].url,
      'https://forumias.com/blog/'
      'must-read-news-daily-current-affairs-articles-6-august-2026/',
    );
  });
}
