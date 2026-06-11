import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Ensures every install has a Firebase Auth uid without showing a login UI.
///
/// Requires **Anonymous** sign-in enabled in Firebase Console:
/// Authentication → Sign-in method → Anonymous → Enable.
class AnonymousAuthService {
  AnonymousAuthService._();

  static Future<void> ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;
    try {
      await auth.signInAnonymously();
    } catch (e, st) {
      debugPrint('AnonymousAuthService.ensureSignedIn: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
