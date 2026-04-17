import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Persists FCM device token on `users/{lowercaseEmail}` for Cloud Function invite delivery.
class FcmTokenSyncService {
  FcmTokenSyncService._();

  static StreamSubscription<String>? _refreshSub;

  static Future<void> syncForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase().trim();
    if (email == null || email.isEmpty) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _writeToken(email: email, token: token);
    } catch (e, st) {
      debugPrint('FcmTokenSyncService.syncForCurrentUser: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static void ensureTokenRefreshSubscription() {
    _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email?.toLowerCase().trim();
        if (email == null || email.isEmpty) return;
        try {
          await _writeToken(email: email, token: token);
        } catch (e, st) {
          debugPrint('FcmTokenSyncService.onTokenRefresh: $e');
          debugPrintStack(stackTrace: st);
        }
      },
    );
  }

  static Future<void> _writeToken({
    required String email,
    required String token,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(email).set(
      {
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
