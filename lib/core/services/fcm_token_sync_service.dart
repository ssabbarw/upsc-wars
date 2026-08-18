import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:upsc_wars/core/constants/super_user_emails.dart';
import 'package:upsc_wars/core/debug/cursor_debug_log.dart';
import 'package:upsc_wars/core/providers/kill_switch_provider.dart';
import 'package:upsc_wars/features/daily_war/daily_war_constants.dart';
import 'package:upsc_wars/features/fomo_pulse/fomo_pulse_constants.dart';
import 'package:upsc_wars/features/push_spot_test/push_spot_test_constants.dart';

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
      await _ensureSpotTestBroadcastTopicSubscription();
      await _ensureFomoPulseTopicSubscription();
      await _ensureDailyWarTopicSubscription(email: email);
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
          await _ensureSpotTestBroadcastTopicSubscription();
          await _ensureFomoPulseTopicSubscription();
          await _ensureDailyWarTopicSubscription(email: email);
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

  static Future<void> _ensureSpotTestBroadcastTopicSubscription() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(
        PushSpotTestConstants.broadcastFcmTopic,
      );
    } catch (e, st) {
      debugPrint('FcmTokenSyncService.subscribeToSpotTestTopic: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> _ensureFomoPulseTopicSubscription() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(
        FomoPulseConstants.broadcastFcmTopic,
      );
    } catch (e, st) {
      debugPrint('FcmTokenSyncService.subscribeToFomoPulseTopic: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> _ensureDailyWarTopicSubscription({
    required String email,
  }) async {
    if (kIsWeb) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      final enabled = rc.getBool(dailyWarEnabledRemoteConfigKey);
      final adminsOnly = rc.getBool(dailyWarAdminsOnlyRemoteConfigKey);
      final isAdmin = SuperUserEmails.contains(email);
      final forUser = enabled && (!adminsOnly || isAdmin);

      final messaging = FirebaseMessaging.instance;
      if (!forUser) {
        await messaging.unsubscribeFromTopic(
          DailyWarConstants.broadcastFcmTopic,
        );
        await messaging.unsubscribeFromTopic(
          DailyWarConstants.adminBroadcastFcmTopic,
        );
        return;
      }
      if (adminsOnly) {
        await messaging.subscribeToTopic(
          DailyWarConstants.adminBroadcastFcmTopic,
        );
        await messaging.unsubscribeFromTopic(
          DailyWarConstants.broadcastFcmTopic,
        );
      } else {
        await messaging.subscribeToTopic(DailyWarConstants.broadcastFcmTopic);
        await messaging.unsubscribeFromTopic(
          DailyWarConstants.adminBroadcastFcmTopic,
        );
      }
    } catch (e, st) {
      debugPrint('FcmTokenSyncService.subscribeToDailyWarTopic: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
