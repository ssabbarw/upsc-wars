import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:upsc_wars/core/router/app_router.dart';
import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';
import 'package:upsc_wars/features/notifications/long_html_notification_constants.dart';

/// FCM setup for battle invites, long HTML announcements, and deep links.
class BattleMessagingService {
  BattleMessagingService._();

  /// Set from [main] after [FirebaseMessaging.instance.getInitialMessage] so
  /// the launch intent is not lost before the router exists.
  static RemoteMessage? _pendingOpenedNotification;

  static GoRouter? _router;

  static void setPendingOpenedNotification(RemoteMessage message) {
    _pendingOpenedNotification = message;
  }

  static Future<void> initialize(GoRouter router) async {
    _router = router;
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

    // Foreground: system tray often does not show; surface payload in-app.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleDataMessage);

    final initial = _pendingOpenedNotification ??
        await messaging.getInitialMessage();
    _pendingOpenedNotification = null;
    if (initial != null) {
      _scheduleNavigateFromOpenedNotification(router, initial);
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title?.trim();
    final bodyRaw = n?.body?.trim();
    final resolvedTitle =
        (title != null && title.isNotEmpty) ? title : 'Message';
    final resolvedBody =
        (bodyRaw != null && bodyRaw.isNotEmpty)
            ? bodyRaw
            : (message.data.isEmpty ? 'New notification' : message.data.toString());
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
      SnackBar(
        content: Text('$resolvedTitle\n$resolvedBody'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  static void _handleDataMessage(RemoteMessage message) {
    final router = _router;
    if (router == null) return;
    _scheduleNavigateFromOpenedNotification(router, message);
  }

  /// Opens the long-HTML announcement screen when FCM **data** has
  /// [LongHtmlNotificationConstants.fcmDataKeyType] ==
  /// [LongHtmlNotificationConstants.fcmDataValueLongHtmlMessage] (case-insensitive).
  static bool messageOpensLongHtmlScreen(RemoteMessage message) {
    final raw = message.data[LongHtmlNotificationConstants.fcmDataKeyType];
    if (raw == null) return false;
    final s = raw.toString().trim().toLowerCase();
    return s == LongHtmlNotificationConstants.fcmDataValueLongHtmlMessage;
  }

  /// Routes after notification open (background / terminated).
  static void _scheduleNavigateFromOpenedNotification(
    GoRouter router,
    RemoteMessage message,
  ) {
    void go() {
      if (kDebugMode) {
        debugPrint('BattleMessagingService: notification opened, data=${message.data}');
      }
      if (messageOpensLongHtmlScreen(message)) {
        router.push('/notification/long-html');
        return;
      }
      final sessionId = message.data['sessionId'] as String?;
      if (sessionId != null && sessionId.isNotEmpty) {
        router.go('/battle/join/$sessionId');
      }
    }

    // Defer one frame so the shell route is committed before [push] (cold
    // start from notification tap).
    WidgetsBinding.instance.addPostFrameCallback((_) => go());
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
