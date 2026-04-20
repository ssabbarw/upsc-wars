import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../domain/chat_ids.dart';
import '../domain/chat_service.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/chat_runtime_config.dart';
import '../domain/entities/chat_thread.dart';

class RealtimeChatService implements ChatService {
  RealtimeChatService(this._db);

  final FirebaseDatabase _db;

  @override
  Stream<List<ChatMessage>> watchMessages({
    required String chatId,
    required int limit,
  }) {
    final query = _db
        .ref('chatMessages/$chatId')
        .orderByChild('createdAt')
        .limitToLast(limit);
    return (() async* {
      yield const <ChatMessage>[];
      yield* query.onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return const <ChatMessage>[];
        final list = <ChatMessage>[];
        raw.forEach((key, value) {
          if (value is! Map) return;
          final map = Map<Object?, Object?>.from(value);
          list.add(
            ChatMessage(
              id: key.toString(),
              chatId: chatId,
              senderEmail: (map['senderEmail'] ?? '').toString(),
              text: (map['text'] ?? '').toString(),
              createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
            ),
          );
        });
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return list;
      });
    })();
  }

  @override
  Stream<List<ChatThread>> watchThreads({required String currentUserEmail}) {
    final userKey = ChatIds.emailKey(currentUserEmail);
    final query = _db
        .ref('chatThreads')
        .orderByChild('participants/$userKey')
        .equalTo(true);
    return (() async* {
      yield const <ChatThread>[];
      yield* query.onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return const <ChatThread>[];
        final threads = <ChatThread>[];
        raw.forEach((key, value) {
          if (value is! Map) return;
          final map = Map<Object?, Object?>.from(value);
          final participants = <String>[];
          final participantsRaw = map['participantEmails'];
          if (participantsRaw is List) {
            for (final item in participantsRaw) {
              final email = item?.toString() ?? '';
              if (email.isNotEmpty) participants.add(email);
            }
          }
          final unreadMap = map['unread'];
          final unread = unreadMap is Map
              ? (unreadMap[userKey] as num?)?.toInt() ?? 0
              : 0;
          threads.add(
            ChatThread(
              chatId: key.toString(),
              participantEmails: participants,
              lastMessageText: (map['lastMessageText'] ?? '').toString().isEmpty
                  ? null
                  : (map['lastMessageText'] ?? '').toString(),
              lastMessageAt: (map['lastMessageAt'] as num?)?.toInt(),
              updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
              unreadCount: unread,
            ),
          );
        });
        threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return threads;
      });
    })();
  }

  @override
  Stream<bool> watchIsTyping({
    required String chatId,
    required String peerEmail,
    required ChatRuntimeConfig config,
  }) {
    if (!config.enableTypingIndicator) {
      return Stream<bool>.value(false);
    }
    final key = ChatIds.emailKey(peerEmail);
    final ref = _db.ref('chatTyping/$chatId/$key');
    return ref.onValue.map((event) => event.snapshot.value == true);
  }

  @override
  Stream<bool> watchIsOnline({
    required String peerEmail,
    required ChatRuntimeConfig config,
  }) {
    if (!config.enableOnlineIndicator) {
      return Stream<bool>.value(false);
    }
    final key = ChatIds.emailKey(peerEmail);
    final ref = _db.ref('presence/$key/isOnline');
    return ref.onValue.map((event) => event.snapshot.value == true);
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String currentUserEmail,
    required String peerEmail,
    required String text,
    required ChatRuntimeConfig config,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final now = ServerValue.timestamp;
    final current = currentUserEmail.trim().toLowerCase();
    final peer = peerEmail.trim().toLowerCase();
    final currentKey = ChatIds.emailKey(current);
    final peerKey = ChatIds.emailKey(peer);

    final messageRef = _db.ref('chatMessages/$chatId').push();
    await messageRef.set({
      'senderEmail': current,
      'text': trimmed,
      'createdAt': now,
    });

    final updates = <String, Object?>{
      'chatThreads/$chatId/participantEmails': [current, peer]..sort(),
      'chatThreads/$chatId/participants/$currentKey': true,
      'chatThreads/$chatId/participants/$peerKey': true,
      'chatThreads/$chatId/lastMessageText': trimmed,
      'chatThreads/$chatId/lastMessageBy': current,
      'chatThreads/$chatId/lastMessageAt': now,
      'chatThreads/$chatId/updatedAt': now,
    };
    if (config.enableUnreadCount) {
      updates['chatThreads/$chatId/unread/$peerKey'] = ServerValue.increment(1);
      updates['chatThreads/$chatId/unread/$currentKey'] = 0;
    }
    await _db.ref().update(updates);
  }

  @override
  Future<void> setTyping({
    required String chatId,
    required String currentUserEmail,
    required bool isTyping,
    required ChatRuntimeConfig config,
  }) async {
    if (!config.enableTypingIndicator) return;
    final key = ChatIds.emailKey(currentUserEmail);
    final ref = _db.ref('chatTyping/$chatId/$key');
    if (isTyping) {
      await ref.set(true);
      unawaited(ref.onDisconnect().remove());
      return;
    }
    await ref.remove();
  }

  @override
  Future<void> markThreadRead({
    required String chatId,
    required String currentUserEmail,
    required ChatRuntimeConfig config,
  }) async {
    if (!config.enableUnreadCount) return;
    final key = ChatIds.emailKey(currentUserEmail);
    await _db.ref('chatThreads/$chatId/unread/$key').set(0);
  }

  @override
  Future<void> setOnline({
    required String currentUserEmail,
    required bool isOnline,
    required ChatRuntimeConfig config,
  }) async {
    if (!config.enableOnlineIndicator) return;
    final key = ChatIds.emailKey(currentUserEmail);
    final ref = _db.ref('presence/$key');
    if (isOnline) {
      await ref.update({
        'isOnline': true,
        'lastSeenAt': ServerValue.timestamp,
      });
      unawaited(
        ref.onDisconnect().update({
          'isOnline': false,
          'lastSeenAt': ServerValue.timestamp,
        }),
      );
      return;
    }
    await ref.update({
      'isOnline': false,
      'lastSeenAt': ServerValue.timestamp,
    });
  }
}
