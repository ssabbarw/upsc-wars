import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';

/// Result of [BattleSelfTestPushCloudService.sendTestNotificationToSelf].
class SelfPushTestOutcome {
  const SelfPushTestOutcome._({
    required this.notificationSent,
    this.serverReason,
    this.transportError,
  });

  final bool notificationSent;
  final String? serverReason;
  final Object? transportError;

  String get userFacingMessage {
    if (transportError != null) {
      if (transportError is FirebaseFunctionsException) {
        final e = transportError as FirebaseFunctionsException;
        return e.message ?? e.code;
      }
      return transportError.toString();
    }
    if (notificationSent) {
      return 'Test notification sent. If the app was open, look for a '
          'SnackBar at the bottom; otherwise check the notification tray.';
    }
    if (serverReason == 'notifications_denied') {
      return 'Notifications are off for this app. Enable them in system '
          'Settings, then try again.';
    }
    if (serverReason == 'no_token') {
      return 'No push token on your user doc. Open the app once after sign-in, or check permissions.';
    }
    if (serverReason == 'send_failed') {
      return 'FCM could not deliver the test. Check Firebase Console logs.';
    }
    return 'Test finished with an unexpected result.';
  }
}

/// HTTPS callable `sendSelfTestNotification` — sends FCM to the signed-in user only.
class BattleSelfTestPushCloudService {
  const BattleSelfTestPushCloudService();

  Future<SelfPushTestOutcome> sendTestNotificationToSelf() async {
    if (!kIsWeb) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return const SelfPushTestOutcome._(
          notificationSent: false,
          serverReason: 'notifications_denied',
        );
      }
    }
    await FcmTokenSyncService.syncForCurrentUser();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendSelfTestNotification',
      );
      final result = await callable.call<Map<String, dynamic>>({});
      final data = result.data;
      if (data['ok'] == true) {
        debugPrint('sendSelfTestNotification: ok');
        return const SelfPushTestOutcome._(notificationSent: true);
      }
      final reason = data['reason']?.toString();
      debugPrint('sendSelfTestNotification: ok=false reason=$reason');
      return SelfPushTestOutcome._(
        notificationSent: false,
        serverReason: reason,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'sendSelfTestNotification FirebaseFunctionsException: ${e.code} ${e.message}',
      );
      debugPrintStack(stackTrace: st);
      return SelfPushTestOutcome._(
        notificationSent: false,
        transportError: e,
      );
    } catch (e, st) {
      debugPrint('sendSelfTestNotification: $e');
      debugPrintStack(stackTrace: st);
      return SelfPushTestOutcome._(
        notificationSent: false,
        transportError: e,
      );
    }
  }
}
