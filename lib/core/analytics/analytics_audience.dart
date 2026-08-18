import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_session.dart';
import '../auth/super_user.dart';

/// Who must not contribute product analytics (GA4, Drift, admin dashboard).
///
/// Debug builds never capture. Admins are listed super-user emails. Bots use
/// reserved mailbox domains so they cannot collide with Google/Apple sign-in.
abstract final class AnalyticsAudience {
  AnalyticsAudience._();

  static const reservedBotEmailDomains = {
    'community.upscwars.in',
    'upscwars.bot',
  };

  static bool isReservedBotEmail(String? email) {
    final domain = _emailDomain(email);
    return domain.isNotEmpty && reservedBotEmailDomains.contains(domain);
  }

  static bool isExcluded({
    String? email,
    bool accountSignedIn = false,
    bool isBot = false,
    bool? debugMode,
  }) {
    if (debugMode ?? kDebugMode) return true;
    if (isBot) return true;
    if (isReservedBotEmail(email)) return true;
    return accountSignedIn && SuperUser.isEmail(email);
  }

  /// Current Firebase user, plus debug builds. False if Auth is not ready.
  static bool isCurrentUserExcluded() {
    if (kDebugMode) return true;
    try {
      return isExcludedUser(FirebaseAuth.instance.currentUser);
    } on Object {
      return false;
    }
  }

  static bool isExcludedUser(User? user, {bool isBot = false}) {
    return isExcluded(
      email: user?.email,
      accountSignedIn: AuthSession.isAccountSignedIn(user),
      isBot: isBot,
    );
  }

  static String _emailDomain(String? email) {
    final e = email?.trim().toLowerCase() ?? '';
    final at = e.lastIndexOf('@');
    if (at < 0 || at == e.length - 1) return '';
    return e.substring(at + 1);
  }
}
