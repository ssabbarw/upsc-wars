import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../../core/admin_dashboard/admin_dashboard_service.dart';

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
    final inboxKey = ChatIds.rulesEmailKey(currentUserEmail);
    final ref = _db.ref('userChats/$inboxKey');
    return (() async* {
      yield const <ChatThread>[];
      yield* ref.onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return const <ChatThread>[];
        final threads = <ChatThread>[];
        raw.forEach((key, value) {
          if (value is! Map) return;
          final map = Map<Object?, Object?>.from(value);
          final participants = _emailsFrom(map['participantEmails']);
          final text = (map['lastMessageText'] ?? '').toString();
          threads.add(
            ChatThread(
              chatId: key.toString(),
              participantEmails: participants,
              lastMessageText: text.isEmpty ? null : text,
              lastMessageAt: (map['lastMessageAt'] as num?)?.toInt(),
              updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
              unreadCount: (map['unread'] as num?)?.toInt() ?? 0,
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
    final key = ChatIds.rulesEmailKey(peerEmail);
    final ref = _db.ref('chatTyping/$chatId/$key');
    return _watchBool(ref);
  }

  @override
  Stream<bool> watchIsOnline({
    required String peerEmail,
    required ChatRuntimeConfig config,
  }) {
    if (!config.enableOnlineIndicator) {
      return Stream<bool>.value(false);
    }
    final key = ChatIds.rulesEmailKey(peerEmail);
    final ref = _db.ref('presence/$key/isOnline');
    return _watchBool(ref);
  }

  @override
  Future<void> syncAuthEmail({
    required String uid,
    required String email,
  }) async {
    final trimmed = email.trim().toLowerCase();
    if (uid.isEmpty || trimmed.isEmpty) return;
    await _db.ref('userEmails/$uid').set(trimmed);
  }

  @override
  Future<void> ensureThread({
    required String chatId,
    required String currentUserEmail,
    required String peerEmail,
  }) async {
    final current = currentUserEmail.trim().toLowerCase();
    final peer = peerEmail.trim().toLowerCase();
    if (current.isEmpty || peer.isEmpty || current == peer) return;
    await _db.ref('chatThreads/$chatId').update({
      'participantEmails': [current, peer]..sort(),
      'participants/${ChatIds.emailKey(current)}': true,
      'participants/${ChatIds.emailKey(peer)}': true,
    });
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
    final currentInbox = ChatIds.rulesEmailKey(current);
    final peerInbox = ChatIds.rulesEmailKey(peer);

    await _db.ref('chatThreads/$chatId').update({
      'participantEmails': [current, peer]..sort(),
      'participants/$currentKey': true,
      'participants/$peerKey': true,
      'lastMessageText': trimmed,
      'lastMessageBy': current,
      'lastMessageAt': now,
      'updatedAt': now,
      if (config.enableUnreadCount) ...{
        'unread/$peerKey': ServerValue.increment(1),
        'unread/$currentKey': 0,
      },
    });

    final messageRef = _db.ref('chatMessages/$chatId').push();
    final participants = [current, peer]..sort();
    final inbox = <String, Object?>{
      'participantEmails': participants,
      'lastMessageText': trimmed,
      'lastMessageAt': now,
      'updatedAt': now,
    };
    await messageRef.set({
      'senderEmail': current,
      'text': trimmed,
      'createdAt': now,
    });
    await _db.ref('userChats/$currentInbox/$chatId').update({
      ...inbox,
      'unread': 0,
    });
    await _db.ref('userChats/$peerInbox/$chatId').update({
      ...inbox,
      'unread': config.enableUnreadCount ? ServerValue.increment(1) : 0,
    });
    unawaited(AdminDashboardWriterService().recordChatEngagement());
  }

  @override
  Future<void> setTyping({
    required String chatId,
    required String currentUserEmail,
    required bool isTyping,
    required ChatRuntimeConfig config,
  }) async {
    if (!config.enableTypingIndicator) return;
    final key = ChatIds.rulesEmailKey(currentUserEmail);
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
    final inboxKey = ChatIds.rulesEmailKey(currentUserEmail);
    await _db.ref('chatThreads/$chatId/unread/$key').set(0);
    await _db.ref('userChats/$inboxKey/$chatId/unread').set(0);
  }

  @override
  Future<void> setOnline({
    required String currentUserEmail,
    required bool isOnline,
    required ChatRuntimeConfig config,
  }) async {
    if (!config.enableOnlineIndicator) return;
    final key = ChatIds.rulesEmailKey(currentUserEmail);
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

Stream<bool> _watchBool(DatabaseReference ref) {
  return ref.onValue
      .map((event) => event.snapshot.value == true)
      .transform(
        StreamTransformer<bool, bool>.fromHandlers(
          handleError: (error, stack, sink) {
            sink.add(false);
          },
        ),
      );
}

List<String> _emailsFrom(Object? raw) {
  final emails = <String>[];
  if (raw is List) {
    for (final item in raw) {
      final email = item?.toString().trim() ?? '';
      if (email.isNotEmpty) emails.add(email);
    }
  } else if (raw is Map) {
    final keys = raw.keys.map((k) => k.toString()).toList()..sort();
    for (final key in keys) {
      final email = raw[key]?.toString().trim() ?? '';
      if (email.isNotEmpty) emails.add(email);
    }
  }
  return emails;
}
