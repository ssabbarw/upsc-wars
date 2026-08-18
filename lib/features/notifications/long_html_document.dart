/// Turns Firestore HTML (fragment or full document) into a mobile WebView page.
abstract final class LongHtmlDocument {
  LongHtmlDocument._();

  static const viewportMeta =
      '<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">';

  static bool isFullDocument(String html) {
    final t = html.trimLeft().toLowerCase();
    return t.startsWith('<!doctype') || t.startsWith('<html');
  }

  /// CSS that keeps pasted pages on a phone: no horizontal overflow, images scale.
  static String mobileCss({required String backgroundCss}) =>
      '''
html, body {
  margin: 0;
  padding: 0;
  background: $backgroundCss;
  max-width: 100%;
  overflow-x: hidden;
  -webkit-text-size-adjust: 100%;
}
img, video, iframe { max-width: 100% !important; height: auto; }
table { max-width: 100% !important; }
td, th { word-wrap: break-word; overflow-wrap: anywhere; }
* { box-sizing: border-box; }
''';

  /// Complete HTML document for [WebViewController.loadHtmlString].
  static String forWebView(String raw, {required String backgroundCss}) {
    final html = raw.trim();
    if (html.isEmpty) return _wrapFragment('', backgroundCss: backgroundCss);
    if (!isFullDocument(html)) {
      return _wrapFragment(html, backgroundCss: backgroundCss);
    }
    return _injectIntoExisting(html, backgroundCss: backgroundCss);
  }

  /// Inner markup for the web [HtmlWidget] fallback (no `<title>`).
  static String forHtmlWidget(String raw) {
    final html = raw.trim();
    if (html.isEmpty) return '';
    final styles = _headStyles(html);
    final body = _bodyInner(html);
    if (styles.isEmpty) return body;
    return '<style>$styles</style>$body';
  }

  static String _wrapFragment(String inner, {required String backgroundCss}) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
$viewportMeta
<style>
${mobileCss(backgroundCss: backgroundCss)}
body {
  padding: 16px 16px 32px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  color: #1c1c1e;
}
</style>
</head>
<body>
$inner
</body>
</html>''';
  }

  static String _injectIntoExisting(String html, {required String backgroundCss}) {
    final extras = StringBuffer()
      ..write(viewportMeta)
      ..write('<style>')
      ..write(mobileCss(backgroundCss: backgroundCss))
      ..write('</style>');
    final head = RegExp('<head[^>]*>', caseSensitive: false).firstMatch(html);
    if (head != null) {
      final at = head.end;
      return '${html.substring(0, at)}$extras${html.substring(at)}';
    }
    final htmlTag = RegExp('<html[^>]*>', caseSensitive: false).firstMatch(html);
    if (htmlTag != null) {
      final at = htmlTag.end;
      return '${html.substring(0, at)}<head>$extras</head>${html.substring(at)}';
    }
    return _wrapFragment(html, backgroundCss: backgroundCss);
  }

  static String _bodyInner(String html) {
    final match = RegExp(
      r'<body[^>]*>([\s\S]*)</body>',
      caseSensitive: false,
    ).firstMatch(html);
    if (match != null) return match.group(1)!.trim();
    return html;
  }

  static String _headStyles(String html) {
    final head = RegExp(
      r'<head[^>]*>([\s\S]*)</head>',
      caseSensitive: false,
    ).firstMatch(html);
    if (head == null) return '';
    final buf = StringBuffer();
    for (final style in RegExp(
      r'<style[^>]*>([\s\S]*?)</style>',
      caseSensitive: false,
    ).allMatches(head.group(1)!)) {
      buf.write(style.group(1));
      buf.write('\n');
    }
    return buf.toString().trim();
  }
}
