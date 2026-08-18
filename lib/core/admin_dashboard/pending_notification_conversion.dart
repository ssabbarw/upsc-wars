import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/battle_messaging_service.dart';
import '../../features/community/open_challenge/open_challenge_fcm.dart';
import '../../features/memory_pairs/push/push_memory_pairs_fcm.dart';
import '../../features/mini_games/push/push_revision_game_fcm.dart';
import '../../features/notifications/long_html_notification_constants.dart';
import '../../features/fomo_pulse/fomo_pulse_fcm.dart';
import '../../features/push_spot_test/push_spot_test_fcm.dart';

/// Holds the most recently opened notification so a follow-up action (test,
/// memory game, battle join) can be counted as a conversion.
abstract final class PendingNotificationConversion {
  PendingNotificationConversion._();

  static String? notificationId;
  static String? kind;

  static void captureFromFcm(RemoteMessage message) {
    final id = notificationIdFromData(message.data);
    if (id == null) return;
    notificationId = id;
    kind = _kindFromData(message.data, message: message);
  }

  /// Resolves a stable id for Firestore notification stats.
  static String? notificationIdFromData(Map<String, dynamic> data) =>
      _notificationIdFromData(data);

  static void captureFromLocalKind(String localKind) {
    notificationId = 'local__$localKind';
    kind = localKind;
  }

  static ({String id, String? kind})? take() {
    final id = notificationId;
    if (id == null || id.isEmpty) return null;
    final k = kind;
    notificationId = null;
    kind = null;
    return (id: id, kind: k);
  }

  static void clear() {
    notificationId = null;
    kind = null;
  }

  static String? _notificationIdFromData(Map<String, dynamic> data) {
    final explicit = data['notification_id']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final kind = data['kind']?.toString().trim().toLowerCase();
    if (kind == PushSpotTestFcm.kind) {
      final subject = data[PushSpotTestFcm.dataKeySubject]?.toString() ?? '';
      final topic = data[PushSpotTestFcm.dataKeyTopic]?.toString() ?? '';
      final uuid = data[PushSpotTestFcm.dataKeyQuestionUuid]?.toString() ?? '';
      return 'spot__${subject}__${topic}__${uuid}';
    }
    if (kind == FomoPulseFcm.kind) {
      final pulseId = FomoPulseFcm.pulseIdFromData(data) ?? '';
      return pulseId.isNotEmpty ? 'pulse__$pulseId' : null;
    }
    if (kind == PushMemoryPairsFcm.kind) {
      final setId = PushMemoryPairsFcm.setIdFromData(data) ?? '';
      return 'memory__$setId';
    }
    if (kind == PushRevisionGameFcm.kind) {
      final gameId = PushRevisionGameFcm.gameIdFromData(data) ?? '';
      return 'revision_game__$gameId';
    }
    if (kind == OpenChallengeFcm.kind) {
      final id = data[OpenChallengeFcm.challengeId]?.toString().trim() ?? '';
      if (id.isNotEmpty) return 'open_challenge__$id';
    }

    final sessionId = data['sessionId']?.toString().trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      return 'battle__$sessionId';
    }

    final longHtmlType = data[LongHtmlNotificationConstants.fcmDataKeyType]
        ?.toString()
        .trim()
        .toLowerCase();
    if (longHtmlType ==
        LongHtmlNotificationConstants.fcmDataValueLongHtmlMessage) {
      return 'long_html__$longHtmlType';
    }

    return null;
  }

  static String? _kindFromData(
    Map<String, dynamic> data, {
    required RemoteMessage message,
  }) {
    if (BattleMessagingService.messageOpensLongHtmlScreen(message)) {
      return 'long_html';
    }
    final raw = data['kind']?.toString().trim().toLowerCase();
    if (raw != null && raw.isNotEmpty) return raw;
    final sid = data['sessionId']?.toString().trim() ?? '';
    if (sid.isNotEmpty) return 'battle_join';
    return null;
  }
}
