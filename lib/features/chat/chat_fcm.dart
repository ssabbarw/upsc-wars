import 'domain/entities/chat_thread_route_payload.dart';

/// FCM data contract for chat message notifications.
///
/// Keep in sync with `functions/index.js` `onChatMessageCreated`.
abstract final class ChatFcm {
  static const kind = 'chat_message';

  static const dataKeyKind = 'kind';
  static const dataKeyChatId = 'chatId';
  static const dataKeySenderEmail = 'senderEmail';
  static const dataKeySenderName = 'senderName';

  static const queryPeerEmail = 'peer';
  static const queryPeerName = 'name';

  static const _localPayloadPath = 'chat_message';

  static String? chatIdFromData(Map<String, dynamic> data) =>
      _nonEmpty(data[dataKeyChatId]);

  static String? senderEmailFromData(Map<String, dynamic> data) =>
      _nonEmpty(data[dataKeySenderEmail])?.toLowerCase();

  static String? senderNameFromData(Map<String, dynamic> data) =>
      _nonEmpty(data[dataKeySenderName]);

  static String threadLocation({
    required String chatId,
    required String peerEmail,
    String? peerName,
  }) {
    final name = peerName?.trim() ?? '';
    return Uri(
      path: '/chat/${chatId.trim()}',
      queryParameters: {
        queryPeerEmail: peerEmail.trim().toLowerCase(),
        if (name.isNotEmpty) queryPeerName: name,
      },
    ).toString();
  }

  static ChatThreadRoutePayload payloadFromRoute({
    Object? extra,
    Map<String, String> queryParameters = const {},
    String? notificationTitle,
  }) {
    if (extra is ChatThreadRoutePayload) return extra;
    final email = queryParameters[queryPeerEmail]?.trim().toLowerCase() ?? '';
    final name = queryParameters[queryPeerName]?.trim();
    final fallbackName = notificationTitle?.trim();
    return ChatThreadRoutePayload(
      peerEmail: email,
      peerDisplayName: (name != null && name.isNotEmpty)
          ? name
          : (fallbackName != null && fallbackName.isNotEmpty
                ? fallbackName
                : 'UPSC Warrior'),
    );
  }

  /// Local-notification payload so a foreground Android tap can open the thread.
  static String localPayload({
    required String chatId,
    required String senderEmail,
    String? senderName,
  }) {
    final name = senderName?.trim() ?? '';
    return Uri(
      path: _localPayloadPath,
      queryParameters: {
        dataKeyChatId: chatId.trim(),
        dataKeySenderEmail: senderEmail.trim().toLowerCase(),
        if (name.isNotEmpty) dataKeySenderName: name,
      },
    ).toString();
  }

  static ({String chatId, String senderEmail, String senderName})?
  parseLocalPayload(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || uri.path != _localPayloadPath) return null;
    final chatId = uri.queryParameters[dataKeyChatId]?.trim() ?? '';
    final senderEmail =
        uri.queryParameters[dataKeySenderEmail]?.trim().toLowerCase() ?? '';
    if (chatId.isEmpty || senderEmail.isEmpty) return null;
    final name = uri.queryParameters[dataKeySenderName]?.trim();
    return (
      chatId: chatId,
      senderEmail: senderEmail,
      senderName: (name != null && name.isNotEmpty) ? name : 'UPSC Warrior',
    );
  }

  static String? _nonEmpty(Object? raw) {
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }
}
