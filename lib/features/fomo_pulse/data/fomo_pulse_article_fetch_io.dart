import 'dart:convert';
import 'dart:io';

const _maxChars = 12000;
const _browserUa =
    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Mobile Safari/537.36';

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Fetches article HTML on-device and returns plain text (avoids server IP blocks).
Future<String?> fetchArticleTextFromUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) return null;

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, _browserUa);
    request.headers.set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8',
    );
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-IN,en;q=0.9');
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    final text = _stripHtml(body);
    if (text.length < 100) return null;
    return text.length > _maxChars ? text.substring(0, _maxChars) : text;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
