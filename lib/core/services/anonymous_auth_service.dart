import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Ensures every install has a Firebase Auth uid without showing a login UI.
///
/// Requires **Anonymous** sign-in enabled in Firebase Console:
/// Authentication → Sign-in method → Anonymous → Enable.
class AnonymousAuthService {
  AnonymousAuthService._();
  static bool _anonymousBlocked = false;
  static bool _loggedAnonymousBlocked = false;

  static Future<bool> ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return true;
    if (_anonymousBlocked) return false;
    try {
      await auth.signInAnonymously();
      return true;
    } on FirebaseAuthException catch (e) {
      // Anonymous sign-in may be disabled in Firebase Console.
      if (e.code == 'admin-restricted-operation' ||
          e.code == 'operation-not-allowed') {
        _anonymousBlocked = true;
        if (!_loggedAnonymousBlocked) {
          _loggedAnonymousBlocked = true;
          debugPrint(
            'AnonymousAuthService: anonymous sign-in disabled; continuing without anonymous user.',
          );
        }
        return false;
      }
      debugPrint('AnonymousAuthService.ensureSignedIn: ${e.code} ${e.message}');
      return false;
    } catch (e, st) {
      debugPrint('AnonymousAuthService.ensureSignedIn: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }
}
