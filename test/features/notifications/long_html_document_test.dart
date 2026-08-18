import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/notifications/long_html_document.dart';

void main() {
  group('LongHtmlDocument.forWebView', () {
    test('wraps a fragment with viewport and padding', () {
      final out = LongHtmlDocument.forWebView(
        '<h1>Daily War</h1>',
        backgroundCss: '#ffffff',
      );
      expect(out, contains('<!DOCTYPE html>'));
      expect(out, contains(LongHtmlDocument.viewportMeta));
      expect(out, contains('<h1>Daily War</h1>'));
      expect(out, contains('overflow-x: hidden'));
      expect(out, contains('padding: 16px 16px 32px'));
      expect(out, isNot(contains('<title>')));
    });

    test('injects viewport into an existing document without showing title as body', () {
      const raw = '''
<!DOCTYPE html>
<html>
<head>
  <title>Daily War is live</title>
  <style>body { color: red; }</style>
</head>
<body>
  <p>Hello</p>
</body>
</html>''';
      final out = LongHtmlDocument.forWebView(raw, backgroundCss: '#f5f5f3');
      expect(out, contains(LongHtmlDocument.viewportMeta));
      expect(out, contains('overflow-x: hidden'));
      expect(out, contains('<p>Hello</p>'));
      expect(out, contains('<title>Daily War is live</title>'));
    });
  });

  group('LongHtmlDocument.forHtmlWidget', () {
    test('drops title and keeps body plus styles', () {
      const raw = '''
<!DOCTYPE html>
<html>
<head>
  <title>Daily War is live</title>
  <style>h1 { color: #c2103a; }</style>
</head>
<body>
  <h1>Entire syllabus</h1>
</body>
</html>''';
      final out = LongHtmlDocument.forHtmlWidget(raw);
      expect(out, isNot(contains('Daily War is live')));
      expect(out, contains('Entire syllabus'));
      expect(out, contains('h1 { color: #c2103a; }'));
    });

    test('passes a fragment through', () {
      expect(
        LongHtmlDocument.forHtmlWidget('<p>Hi</p>'),
        '<p>Hi</p>',
      );
    });
  });
}
