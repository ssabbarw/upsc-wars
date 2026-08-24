import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/chat/chat_fcm.dart';
import 'package:upsc_wars/features/chat/domain/entities/chat_thread_route_payload.dart';

void main() {
  group('ChatFcm', () {
    test('local payload round-trips chatId, email, and name', () {
      final encoded = ChatFcm.localPayload(
        chatId: 'abc123',
        senderEmail: 'Sam@Example.com',
        senderName: 'Sam Warrior',
      );
      final parsed = ChatFcm.parseLocalPayload(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.chatId, 'abc123');
      expect(parsed.senderEmail, 'sam@example.com');
      expect(parsed.senderName, 'Sam Warrior');
    });

    test('thread location encodes peer for router fallback', () {
      expect(
        ChatFcm.threadLocation(
          chatId: 'abc123',
          peerEmail: 'Sam@Example.com',
          peerName: 'Sam Warrior',
        ),
        '/chat/abc123?peer=sam%40example.com&name=Sam+Warrior',
      );
    });

    test('payloadFromRoute prefers extra, else query', () {
      const extra = ChatThreadRoutePayload(
        peerEmail: 'a@b.com',
        peerDisplayName: 'A',
      );
      expect(ChatFcm.payloadFromRoute(extra: extra).peerEmail, 'a@b.com');
      final fromQuery = ChatFcm.payloadFromRoute(
        queryParameters: {'peer': 'c@d.com', 'name': 'C'},
      );
      expect(fromQuery.peerEmail, 'c@d.com');
      expect(fromQuery.peerDisplayName, 'C');
    });
  });
}
