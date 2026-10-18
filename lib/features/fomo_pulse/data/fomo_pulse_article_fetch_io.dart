import 'dart:convert';
import 'dart:io';

const _maxChars = 12000;
const _minUsefulChars = 40;
const _browserUas = [
  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
];

String _stripHtml(String html) {
  return html
      .replaceAll(
        RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Future<String?> _fetchDirect(Uri uri, String userAgent) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, userAgent);
    request.headers.set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8',
    );
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-IN,en;q=0.9');
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final body = await response.transform(utf8.decoder).join();
    final text = _stripHtml(body);
    if (text.length < _minUsefulChars) return null;
    return text.length > _maxChars ? text.substring(0, _maxChars) : text;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

Future<String?> _fetchViaReader(Uri uri) async {
  final readerUri = Uri.parse(
    'https://r.jina.ai/http://${uri.toString().replaceFirst(RegExp(r'^https?://'), '')}',
  );
  return _fetchDirect(readerUri, _browserUas.first);
}

/// Fetches article HTML on-device and returns plain text (avoids server IP blocks).
Future<String?> fetchArticleTextFromUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) return null;

  for (final ua in _browserUas) {
    final text = await _fetchDirect(uri, ua);
    if (text != null && text.length >= _minUsefulChars) return text;
  }

  final readerText = await _fetchViaReader(uri);
  if (readerText != null && readerText.length >= _minUsefulChars) {
    return readerText;
  }
  return null;
}
