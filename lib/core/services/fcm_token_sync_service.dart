import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:upsc_wars/core/debug/cursor_debug_log.dart';

/// Persists FCM device token on `users/{lowercaseEmail}` for Cloud Function invite delivery.
class FcmTokenSyncService {
  FcmTokenSyncService._();

  static StreamSubscription<String>? _refreshSub;

  static Future<void> syncForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase().trim();
    if (email == null || email.isEmpty) {
      // #region agent log
      unawaited(
        CursorDebugLog.write(
          hypothesisId: 'C',
          location: 'fcm_token_sync_service.dart:syncForCurrentUser',
          message: 'No email; skipping token sync',
          data: {
            'hasUser': user != null,
          },
        ),
      );
      // #endregion
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      // #region agent log
      unawaited(
        CursorDebugLog.write(
          hypothesisId: 'B',
          location: 'fcm_token_sync_service.dart:syncForCurrentUser',
          message: 'Fetched FCM token for sync',
          data: {
            'fcmTokenPresent': token != null && token.trim().isNotEmpty,
          },
        ),
      );
      // #endregion
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
          // #region agent log
          unawaited(
            CursorDebugLog.write(
              hypothesisId: 'B',
              location: 'fcm_token_sync_service.dart:onTokenRefresh',
              message: 'onTokenRefresh fired',
              data: {
                'fcmTokenPresent': token.trim().isNotEmpty,
              },
            ),
          );
          // #endregion
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
