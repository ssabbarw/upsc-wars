import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';
import 'package:upsc_wars/features/notifications/long_html_notification_constants.dart';
import 'package:upsc_wars/features/push_spot_test/push_spot_test_constants.dart';

/// Who receives [BroadcastAnnouncementCloudService.send].
enum BroadcastAnnouncementTarget { self, broadcast }

/// Live `Long_Html_Message/message` document.
class SavedLongHtmlMessage {
  const SavedLongHtmlMessage({required this.html, this.title = ''});

  final String html;
  final String title;

  bool get isEmpty => html.trim().isEmpty;
}

/// Result of save or send.
class BroadcastAnnouncementOutcome {
  const BroadcastAnnouncementOutcome._({
    required this.ok,
    this.saved = false,
    this.notificationSent = false,
    this.target,
    this.notificationId,
    this.serverReason,
    this.transportError,
  });

  final bool ok;
  final bool saved;
  final bool notificationSent;
  final BroadcastAnnouncementTarget? target;
  final String? notificationId;
  final String? serverReason;
  final Object? transportError;

  String get userFacingMessage {
    if (transportError != null) {
      if (transportError is FirebaseFunctionsException) {
        final e = transportError as FirebaseFunctionsException;
        if (e.code == 'not-found' ||
            (e.message?.contains('NOT_FOUND') ?? false)) {
          return 'Function not deployed yet. Run '
              'firebase deploy --only functions:saveLongHtmlMessage,'
              'functions:sendBroadcastAnnouncement';
        }
        if (e.code == 'permission-denied') {
          return 'This account is not allowed to send broadcasts.';
        }
        return e.message ?? e.code;
      }
      return transportError.toString();
    }
    if (saved && !notificationSent) {
      return 'Long HTML message saved. Users who open it will see the new page.';
    }
    if (notificationSent) {
      final suffix = saved ? ' Long HTML was saved too.' : '';
      if (target == BroadcastAnnouncementTarget.broadcast) {
        return 'Broadcast sent to devices on '
            '"${PushSpotTestConstants.broadcastFcmTopic}".$suffix';
      }
      return 'Sent to your phone. Check the notification tray.$suffix';
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
    if (serverReason == 'no_html') {
      return 'No long HTML is saved yet. Save the announcement first, or turn off “Open as long HTML”.';
    }
    return 'Finished with an unexpected result.';
  }
}

/// Payload for HTTPS callable `sendBroadcastAnnouncement`.
class BroadcastAnnouncementRequest {
  const BroadcastAnnouncementRequest({
    required this.title,
    required this.body,
    required this.target,
    this.html = '',
    this.openLongHtml = false,
    this.saveHtml = false,
    this.kind = 'announcement',
  });

  final String title;
  final String body;
  final BroadcastAnnouncementTarget target;
  final String html;
  final bool openLongHtml;
  final bool saveHtml;
  final String kind;

  Map<String, dynamic> toCallableMap() {
    return <String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      'html': html.trim(),
      'openLongHtml': openLongHtml,
      'saveHtml': saveHtml && html.trim().isNotEmpty,
      'kind': kind.trim().isEmpty ? 'announcement' : kind.trim(),
      'target': target == BroadcastAnnouncementTarget.broadcast
          ? 'broadcast'
          : 'self',
    };
  }
}

/// Save / load long HTML and send FCM separately.
class BroadcastAnnouncementCloudService {
  const BroadcastAnnouncementCloudService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<SavedLongHtmlMessage> loadSavedHtml() async {
    final doc = await _db
        .collection(LongHtmlNotificationConstants.collection)
        .doc(LongHtmlNotificationConstants.documentId)
        .get();
    final data = doc.data();
    final html = data?[LongHtmlNotificationConstants.fieldMessage];
    final title = data?['title'];
    return SavedLongHtmlMessage(
      html: html is String ? html.trim() : '',
      title: title is String ? title.trim() : '',
    );
  }

  Future<BroadcastAnnouncementOutcome> saveHtml({
    required String html,
    String title = '',
  }) async {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return const BroadcastAnnouncementOutcome._(
        ok: false,
        serverReason: 'no_html',
      );
    }
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'saveLongHtmlMessage',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'html': trimmed,
        'title': title.trim(),
      });
      final data = result.data;
      if (data['ok'] == true) {
        return const BroadcastAnnouncementOutcome._(ok: true, saved: true);
      }
      return BroadcastAnnouncementOutcome._(
        ok: false,
        serverReason: data['reason']?.toString(),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'saveLongHtmlMessage FirebaseFunctionsException: ${e.code} ${e.message}',
      );
      debugPrintStack(stackTrace: st);
      return BroadcastAnnouncementOutcome._(ok: false, transportError: e);
    } catch (e, st) {
      debugPrint('saveLongHtmlMessage: $e');
      debugPrintStack(stackTrace: st);
      return BroadcastAnnouncementOutcome._(ok: false, transportError: e);
    }
  }

  Future<BroadcastAnnouncementOutcome> send(
    BroadcastAnnouncementRequest request,
  ) async {
    if (request.target == BroadcastAnnouncementTarget.self && !kIsWeb) {
      final status =
          await BattleMessagingService.notificationAuthorizationStatus();
      if (status == AuthorizationStatus.denied ||
          status == AuthorizationStatus.deniedPermanently) {
        return const BroadcastAnnouncementOutcome._(
          ok: false,
          serverReason: 'notifications_denied',
        );
      }
    }
    await FcmTokenSyncService.syncForCurrentUser();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendBroadcastAnnouncement',
      );
      final result = await callable.call<Map<String, dynamic>>(
        request.toCallableMap(),
      );
      final data = result.data;
      if (data['ok'] == true) {
        final targetRaw = data['target']?.toString();
        final target = targetRaw == 'broadcast'
            ? BroadcastAnnouncementTarget.broadcast
            : BroadcastAnnouncementTarget.self;
        return BroadcastAnnouncementOutcome._(
          ok: true,
          saved: request.saveHtml,
          notificationSent: true,
          target: target,
          notificationId: data['notificationId']?.toString(),
        );
      }
      return BroadcastAnnouncementOutcome._(
        ok: false,
        serverReason: data['reason']?.toString(),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'sendBroadcastAnnouncement FirebaseFunctionsException: ${e.code} ${e.message}',
      );
      debugPrintStack(stackTrace: st);
      return BroadcastAnnouncementOutcome._(ok: false, transportError: e);
    } catch (e, st) {
      debugPrint('sendBroadcastAnnouncement: $e');
      debugPrintStack(stackTrace: st);
      return BroadcastAnnouncementOutcome._(ok: false, transportError: e);
    }
  }
}
