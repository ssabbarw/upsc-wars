import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import '../debug/upsc_wars_trace.dart';

/// Distinguishes silent anonymous Firebase sessions from real account sign-in.
abstract final class AuthSession {
  static bool isAccountSignedIn(User? user) =>
      user != null && !user.isAnonymous;

  static bool isCurrentAccountSignedIn() =>
      isAccountSignedIn(FirebaseAuth.instance.currentUser);

  static String? normalizeEmail(String? email) {
    final trimmed = email?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Email from [user.email], then provider profiles (Apple/Google can omit the
  /// top-level field).
  static String? emailOf(User? user) {
    if (user == null) return null;
    final direct = normalizeEmail(user.email);
    if (direct != null) return direct;
    for (final info in user.providerData) {
      final fromProvider = normalizeEmail(info.email);
      if (fromProvider != null) return fromProvider;
    }
    return null;
  }

  static String? currentEmail() => emailOf(FirebaseAuth.instance.currentUser);

  /// Email RTDB security rules will see (`auth.token.email`, then identities).
  static String? emailFromTokenClaims(Map<String, dynamic>? claims) {
    final direct = normalizeEmail(claims?['email']?.toString());
    if (direct != null) return direct;
    final firebase = claims?['firebase'];
    if (firebase is Map) {
      final identities = firebase['identities'];
      if (identities is Map) {
        final emails = identities['email'];
        if (emails is List && emails.isNotEmpty) {
          return normalizeEmail(emails.first.toString());
        }
      }
    }
    return null;
  }

  /// Reads `email` from a raw JWT payload. Flutter's [IdTokenResult.claims]
  /// often omits standard claims even when they are on the token.
  static String? emailFromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    final parts = idToken.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      if (map is! Map) return null;
      return emailFromTokenClaims(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  /// Refreshes the ID token RTDB rules see. Prefers the JWT email, then the
  /// signed-in user's email so chat does not treat a Google session as signed out.
  static Future<String?> refreshTokenEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      upscWarsTrace('AuthSession token: no currentUser');
      return null;
    }
    final result = await user.getIdTokenResult(true);
    final jwtEmail = emailFromIdToken(result.token);
    final claimsEmail = emailFromTokenClaims(result.claims);
    final userEmail = emailOf(user);
    final resolved = jwtEmail ?? claimsEmail ?? userEmail;
    upscWarsTrace(
      'AuthSession token isAnonymous=${user.isAnonymous} '
      'hasUserEmail=${userEmail != null} '
      'hasJwtEmail=${jwtEmail != null} '
      'hasClaimsEmail=${claimsEmail != null} '
      'hasResolvedEmail=${resolved != null} '
      'signInProvider=${result.signInProvider}',
    );
    if (user.isAnonymous && userEmail == null) return null;
    return resolved;
  }
}
