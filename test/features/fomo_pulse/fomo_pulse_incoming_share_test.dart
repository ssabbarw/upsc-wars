import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/fomo_pulse/data/fomo_pulse_incoming_share.dart';

void main() {
  group('extractHttpUrlFromSharedText', () {
    test('returns a bare https URL', () {
      expect(
        extractHttpUrlFromSharedText('https://www.thehindu.com/news/foo'),
        'https://www.thehindu.com/news/foo',
      );
    });

    test('pulls the URL out of Chrome/Safari share text', () {
      expect(
        extractHttpUrlFromSharedText(
          'India news title\nhttps://indianexpress.com/article/india/foo-bar/',
        ),
        'https://indianexpress.com/article/india/foo-bar/',
      );
    });

    test('strips wrapping angle brackets', () {
      expect(
        extractHttpUrlFromSharedText('<https://example.com/a?x=1>'),
        'https://example.com/a?x=1',
      );
    });
  });

  group('incoming CA Shot maker share URI', () {
    const article = 'https://www.thehindu.com/news/national/foo?utm=1';

    test('round-trips through upscwars://pulse-article', () {
      final deep = pulseArticleDeepLinkForUrl(article);
      expect(deep.scheme, 'upscwars');
      expect(deep.host, 'pulse-article');
      expect(articleUrlFromIncomingShareUri(deep), article);
      expect(articleUrlFromIncomingUri(deep), article);
    });

    test('accepts a plain news https URI', () {
      expect(
        articleUrlFromIncomingUri(Uri.parse(article)),
        article,
      );
    });

    test('does not treat upscwars.in product links as articles', () {
      expect(
        articleUrlFromIncomingUri(
          Uri.parse('https://upscwars.in/ca-shot/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
        ),
        isNull,
      );
    });

    test('builds the composer route with the article URL', () {
      final route = pulseArticleRouteForUrl(article);
      expect(route, startsWith('/internal/fomo-pulse-composer/article?'));
      final parsed = Uri.parse(route);
      expect(parsed.queryParameters['url'], article);
    });
  });
}
