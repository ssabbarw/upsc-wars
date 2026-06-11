import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM **data** payload for launching a Memory Pairs set from a push tap.
///
/// Required:
/// * `kind` = [PushMemoryPairsFcm.kind] (`memory_pairs`)
/// * `id` — catalog set id (e.g. `national_parks`)
///
/// Optional (welcome screen copy; falls back to notification title/body):
/// * `title` or `heading`
/// * `body`
abstract final class PushMemoryPairsFcm {
  static const kind = 'memory_pairs';

  static const dataKeyKind = 'kind';
  static const dataKeyId = 'id';
  static const dataKeySet = 'set';
  static const dataKeySetId = 'set_id';
  static const dataKeyTitle = 'title';
  static const dataKeyHeading = 'heading';
  static const dataKeyBody = 'body';

  static String? setIdFromData(Map<String, dynamic> data) {
    for (final key in [dataKeyId, dataKeySet, dataKeySetId]) {
      final raw = data[key];
      final s = raw?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  static String? titleFromMessage(RemoteMessage message) {
    for (final key in [dataKeyTitle, dataKeyHeading]) {
      final raw = message.data[key];
      final s = raw?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    final n = message.notification?.title?.trim();
    if (n != null && n.isNotEmpty) return n;
    return null;
  }

  static String? bodyFromMessage(RemoteMessage message) {
    final raw = message.data[dataKeyBody];
    final s = raw?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
    final n = message.notification?.body?.trim();
    if (n != null && n.isNotEmpty) return n;
    return null;
  }
}
