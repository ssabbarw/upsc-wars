import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';

/// Who receives the spot-test push from the composer.
enum SpotTestSendTarget {
  self,
  broadcast,
}

/// Result of [SpotTestPushCloudService.sendSpotTestNotification].
class SpotTestPushOutcome {
  const SpotTestPushOutcome._({
    required this.notificationSent,
    this.target,
    this.serverReason,
    this.transportError,
  });

  final bool notificationSent;
  final SpotTestSendTarget? target;
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
      if (target == SpotTestSendTarget.broadcast) {
        return 'Broadcast sent to all subscribed devices.';
      }
      return 'Spot-test notification sent. Check the tray or in-app banner.';
    }
    if (serverReason == 'notifications_denied') {
      return 'Notifications are off. Enable them in system Settings, then try again.';
    }
    if (serverReason == 'no_token') {
      return 'No push token on your user doc. Open the app once after sign-in.';
    }
    if (serverReason == 'send_failed') {
      return 'FCM could not deliver. Check Firebase Console logs.';
    }
    if (serverReason == 'invalid_argument') {
      return 'Missing title or body for the notification.';
    }
    if (serverReason == 'not_authorized') {
      return 'Your account is not allowed to broadcast. Set '
          'SPOT_TEST_BROADCAST_EMAILS on the Cloud Function.';
    }
    return 'Send finished with an unexpected result.';
  }
}

/// Payload for [SpotTestPushCloudService.sendSpotTestNotification].
class SpotTestPushRequest {
  const SpotTestPushRequest({
    required this.title,
    required this.body,
    required this.target,
    this.subject,
    this.topic,
    this.subtopic,
    this.questionUuid,
  });

  final String title;
  final String body;
  final SpotTestSendTarget target;
  final String? subject;
  final String? topic;
  final String? subtopic;
  final String? questionUuid;

  Map<String, dynamic> toCallableMap() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      'target': target == SpotTestSendTarget.broadcast ? 'broadcast' : 'self',
    };
    final s = subject?.trim();
    if (s != null && s.isNotEmpty) map['subject'] = s;
    final t = topic?.trim();
    if (t != null && t.isNotEmpty) map['topic'] = t;
    final st = subtopic?.trim();
    if (st != null && st.isNotEmpty) map['subtopic'] = st;
    final q = questionUuid?.trim();
    if (q != null && q.isNotEmpty) map['question_uuid'] = q;
    return map;
  }
}

/// HTTPS callable `sendSpotTestNotification` — FCM to self or broadcast topic.
class SpotTestPushCloudService {
  const SpotTestPushCloudService();

  Future<SpotTestPushOutcome> sendSpotTestNotification(
    SpotTestPushRequest request,
  ) async {
    if (!kIsWeb) {
      final status =
          await BattleMessagingService.notificationAuthorizationStatus();
      if (status == AuthorizationStatus.denied) {
        return const SpotTestPushOutcome._(
          notificationSent: false,
          serverReason: 'notifications_denied',
        );
      }
    }
    await FcmTokenSyncService.syncForCurrentUser();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendSpotTestNotification',
      );
      final result = await callable.call<Map<String, dynamic>>(
        request.toCallableMap(),
      );
      final data = result.data;
      if (data['ok'] == true) {
        debugPrint('sendSpotTestNotification: ok target=${data['target']}');
        final targetRaw = data['target']?.toString();
        final target = targetRaw == 'broadcast'
            ? SpotTestSendTarget.broadcast
            : SpotTestSendTarget.self;
        return SpotTestPushOutcome._(
          notificationSent: true,
          target: target,
        );
      }
      final reason = data['reason']?.toString();
      debugPrint('sendSpotTestNotification: ok=false reason=$reason');
      return SpotTestPushOutcome._(
        notificationSent: false,
        serverReason: reason,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'sendSpotTestNotification FirebaseFunctionsException: ${e.code} ${e.message}',
      );
      debugPrintStack(stackTrace: st);
      return SpotTestPushOutcome._(notificationSent: false, transportError: e);
    } catch (e, st) {
      debugPrint('sendSpotTestNotification: $e');
      debugPrintStack(stackTrace: st);
      return SpotTestPushOutcome._(notificationSent: false, transportError: e);
    }
  }
}
