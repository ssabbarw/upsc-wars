import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:upsc_wars/core/router/app_router.dart';
import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';

/// FCM setup for battle invites and deep links into [BattleJoinScreen].
class BattleMessagingService {
  BattleMessagingService._();

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);

    if (!kIsWeb) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FcmTokenSyncService.ensureTokenRefreshSubscription();

    FirebaseMessaging.onMessageOpenedApp.listen(_handleDataMessage);
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _navigateFromMessage(initial);
    }
  }

  static void _handleDataMessage(RemoteMessage message) {
    _navigateFromMessage(message);
  }

  static void _navigateFromMessage(RemoteMessage message) {
    final sessionId = message.data['sessionId'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    ctx.go('/battle/join/$sessionId');
  }

  /// Returns the device token for storing on `users/{email}` (server targets invites).
  static Future<String?> refreshFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e, st) {
      debugPrint('BattleMessagingService.refreshFcmToken: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }
}
