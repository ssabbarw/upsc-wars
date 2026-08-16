import 'dart:convert';

abstract final class ChatIds {
  static String chatIdForPair(String emailA, String emailB) {
    final a = emailA.trim().toLowerCase();
    final b = emailB.trim().toLowerCase();
    final sorted = [a, b]..sort();
    final raw = '${sorted[0]}|${sorted[1]}';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  static String emailKey(String email) {
    return base64Url.encode(utf8.encode(email.trim().toLowerCase())).replaceAll(
      '=',
      '',
    );
  }

  /// RTDB key rules can recompute from `auth.token.email` (`.` is not allowed in keys).
  static String rulesEmailKey(String email) {
    return email.trim().toLowerCase().replaceAll('.', ',');
  }
}
