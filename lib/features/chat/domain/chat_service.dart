import 'entities/chat_message.dart';
import 'entities/chat_runtime_config.dart';
import 'entities/chat_thread.dart';

abstract class ChatService {
  Stream<List<ChatMessage>> watchMessages({
    required String chatId,
    required int limit,
  });

  Stream<List<ChatThread>> watchThreads({required String currentUserEmail});

  Stream<bool> watchIsTyping({
    required String chatId,
    required String peerEmail,
    required ChatRuntimeConfig config,
  });

  Stream<bool> watchIsOnline({
    required String peerEmail,
    required ChatRuntimeConfig config,
  });

  Future<void> syncAuthEmail({required String uid, required String email});

  Future<void> ensureThread({
    required String chatId,
    required String currentUserEmail,
    required String peerEmail,
  });

  Future<void> sendMessage({
    required String chatId,
    required String currentUserEmail,
    required String peerEmail,
    required String text,
    required ChatRuntimeConfig config,
  });

  Future<void> setTyping({
    required String chatId,
    required String currentUserEmail,
    required bool isTyping,
    required ChatRuntimeConfig config,
  });

  Future<void> markThreadRead({
    required String chatId,
    required String currentUserEmail,
    required ChatRuntimeConfig config,
  });

  Future<void> setOnline({
    required String currentUserEmail,
    required bool isOnline,
    required ChatRuntimeConfig config,
  });
}
