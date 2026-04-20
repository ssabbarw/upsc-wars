import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../home/providers/auth_providers.dart';
import '../data/realtime_chat_service.dart';
import '../domain/chat_service.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/chat_runtime_config.dart';
import '../domain/entities/chat_thread.dart';

const chatEnableOnlineIndicatorKey = 'chat_enable_online_indicator';
const chatEnableTypingIndicatorKey = 'chat_enable_typing_indicator';
const chatEnableUnreadCountKey = 'chat_enable_unread_count';

final chatServiceProvider = Provider<ChatService>((ref) {
  return RealtimeChatService(FirebaseDatabase.instance);
});

final currentUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final email = user?.email?.trim().toLowerCase();
  if (email == null || email.isEmpty) return null;
  return email;
});

class ChatRuntimeConfigNotifier extends AsyncNotifier<ChatRuntimeConfig> {
  @override
  Future<ChatRuntimeConfig> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<ChatRuntimeConfig> _load() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 12),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(minutes: 5),
        ),
      );
      await rc.setDefaults({
        chatEnableOnlineIndicatorKey: true,
        chatEnableTypingIndicatorKey: true,
        chatEnableUnreadCountKey: true,
      });
      await rc.fetchAndActivate();
      return ChatRuntimeConfig(
        enableOnlineIndicator: rc.getBool(chatEnableOnlineIndicatorKey),
        enableTypingIndicator: rc.getBool(chatEnableTypingIndicatorKey),
        enableUnreadCount: rc.getBool(chatEnableUnreadCountKey),
      );
    } catch (_) {
      return ChatRuntimeConfig.defaults;
    }
  }
}

final chatRuntimeConfigProvider =
    AsyncNotifierProvider<ChatRuntimeConfigNotifier, ChatRuntimeConfig>(
      ChatRuntimeConfigNotifier.new,
    );

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
      final service = ref.watch(chatServiceProvider);
      return service.watchMessages(chatId: chatId, limit: 100);
    });

final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final service = ref.watch(chatServiceProvider);
  final email = ref.watch(currentUserEmailProvider);
  if (email == null) return Stream.value(const <ChatThread>[]);
  return service.watchThreads(currentUserEmail: email);
});

final chatTypingProvider = StreamProvider.family
    .autoDispose<bool, ({String chatId, String peerEmail})>((ref, data) {
      final service = ref.watch(chatServiceProvider);
      final config =
          ref.watch(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
      return service.watchIsTyping(
        chatId: data.chatId,
        peerEmail: data.peerEmail,
        config: config,
      );
    });

final chatPresenceProvider = StreamProvider.family.autoDispose<bool, String>((
  ref,
  peerEmail,
) {
  final service = ref.watch(chatServiceProvider);
  final config =
      ref.watch(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
  return service.watchIsOnline(peerEmail: peerEmail, config: config);
});

class ChatComposerNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage({
    required String chatId,
    required String peerEmail,
    required String text,
  }) async {
    final current = ref.read(currentUserEmailProvider);
    if (current == null) {
      throw StateError('You are not signed in. Please sign in and try again.');
    }
    final config =
        ref.read(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
    state = const AsyncLoading();
    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(
            chatId: chatId,
            currentUserEmail: current,
            peerEmail: peerEmail,
            text: text,
            config: config,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      debugPrint('ChatComposerNotifier.sendMessage: $e');
      debugPrintStack(stackTrace: st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    final current = ref.read(currentUserEmailProvider);
    if (current == null) return;
    final config =
        ref.read(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
    await ref
        .read(chatServiceProvider)
        .setTyping(
          chatId: chatId,
          currentUserEmail: current,
          isTyping: isTyping,
          config: config,
        );
  }

  Future<void> markRead(String chatId) async {
    final current = ref.read(currentUserEmailProvider);
    if (current == null) return;
    final config =
        ref.read(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
    await ref
        .read(chatServiceProvider)
        .markThreadRead(
          chatId: chatId,
          currentUserEmail: current,
          config: config,
        );
  }
}

final chatComposerProvider = AsyncNotifierProvider<ChatComposerNotifier, void>(
  ChatComposerNotifier.new,
);
