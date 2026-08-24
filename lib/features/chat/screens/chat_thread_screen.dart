import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../community/domain/entities/community_user.dart';
import '../../community/providers/community_providers.dart';
import '../../community/providers/user_block_providers.dart';
import '../../community/screens/community_screen.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/chat_runtime_config.dart';
import '../providers/chat_providers.dart';

class ChatThreadScreen extends HookConsumerWidget {
  const ChatThreadScreen({
    super.key,
    required this.chatId,
    required this.peerEmail,
    required this.peerDisplayName,
    this.peerPhotoUrl,
  });

  final String chatId;
  final String peerEmail;
  final String peerDisplayName;
  final String? peerPhotoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtdbEmailAsync = ref.watch(chatRtdbEmailProvider);
    final rtdbEmail = rtdbEmailAsync.value;
    final rtdbReady = rtdbEmail != null && rtdbEmail.isNotEmpty;
    final messagesAsync = rtdbReady
        ? ref.watch(chatMessagesProvider(chatId))
        : const AsyncLoading<List<ChatMessage>>();
    final composerState = ref.watch(chatComposerProvider);
    final typingAsync = rtdbReady
        ? ref.watch(
            chatTypingProvider((chatId: chatId, peerEmail: peerEmail)),
          )
        : const AsyncLoading<bool>();
    final presenceAsync = rtdbReady
        ? ref.watch(chatPresenceProvider(peerEmail))
        : const AsyncLoading<bool>();
    final configAsync = ref.watch(chatRuntimeConfigProvider);
    final input = useTextEditingController();
    final scroll = useScrollController();
    final typingTimer = useRef<Timer?>(null);
    final peerNorm = peerEmail.trim().toLowerCase();
    final iBlockedPeer = ref.watch(isPeerBlockedProvider(peerNorm));

    useEffect(() {
      if (!rtdbReady) return null;
      unawaited(() async {
        await ref.read(chatComposerProvider.notifier).ensureThread(
              chatId: chatId,
              peerEmail: peerEmail,
            );
        if (!context.mounted) return;
        ref.read(chatRuntimeConfigProvider.notifier).refresh();
        unawaited(ref.read(chatComposerProvider.notifier).markRead(chatId));
      }());
      return null;
    }, [chatId, peerEmail, rtdbReady]);

    useEffect(() {
      final email = rtdbEmail;
      if (email == null || email.isEmpty) return null;
      final config =
          ref.read(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
      final chatService = ref.read(chatServiceProvider);
      final composer = ref.read(chatComposerProvider.notifier);
      unawaited(() async {
        try {
          await chatService.setOnline(
            currentUserEmail: email,
            isOnline: true,
            config: config,
          );
        } catch (e, st) {
          debugPrint('ChatThreadScreen.setOnline: $e');
          debugPrintStack(stackTrace: st);
        }
      }());
      return () {
        typingTimer.value?.cancel();
        unawaited(
          composer.setTyping(chatId: chatId, isTyping: false),
        );
        unawaited(() async {
          try {
            await chatService.setOnline(
              currentUserEmail: email,
              isOnline: false,
              config: config,
            );
          } catch (_) {}
        }());
      };
    }, [chatId, rtdbEmail]);

    Future<void> send() async {
      if (iBlockedPeer) return;
      final text = input.text.trim();
      if (text.isEmpty) return;
      typingTimer.value?.cancel();
      try {
        await ref.read(chatComposerProvider.notifier).setTyping(
              chatId: chatId,
              isTyping: false,
            );
        await ref.read(chatComposerProvider.notifier).sendMessage(
              chatId: chatId,
              peerEmail: peerEmail,
              text: text,
            );
        input.clear();
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.showText(context, 'Message failed to send: $e');
        }
      }
    }

    void onChanged(String value) {
      if (!rtdbReady) return;
      final config = configAsync.value;
      if (config == null || !config.enableTypingIndicator) return;
      final isTyping = value.trim().isNotEmpty;
      unawaited(
        ref.read(chatComposerProvider.notifier).setTyping(
              chatId: chatId,
              isTyping: isTyping,
            ),
      );
      typingTimer.value?.cancel();
      if (isTyping) {
        typingTimer.value = Timer(const Duration(seconds: 3), () {
          unawaited(
            ref.read(chatComposerProvider.notifier).setTyping(
                  chatId: chatId,
                  isTyping: false,
                ),
          );
        });
      }
    }

    final isOnline = presenceAsync.value == true;
    final showOnline = configAsync.value?.enableOnlineIndicator == true;
    final showTyping = configAsync.value?.enableTypingIndicator == true;

    Future<void> openPeerProfile() async {
      final me = ref.read(currentUserEmailProvider);
      final repo = ref.read(communityRepositoryProvider);
      final loaded = await repo.fetchCommunityUserByEmail(peerEmail);
      final user = loaded ??
          _fallbackPeerCommunityUser(
            peerEmail: peerEmail,
            peerDisplayName: peerDisplayName,
            peerPhotoUrl: peerPhotoUrl,
          );
      if (!context.mounted) return;
      await showCommunityUserProfileSheet(
        context,
        ref,
        user,
        currentUserEmail: me,
        hideSendMessage: true,
        confirmBlockClosesChat: true,
        onBlockedFromChat: () {
          if (context.mounted) context.go('/');
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => unawaited(openPeerProfile()),
          child: Row(
            children: [
              TappableCircularAvatar(
                imageUrl: peerPhotoUrl,
                displayName: peerDisplayName,
                size: 34,
                enableImageTap: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            peerDisplayName,
                            style: AppTextStyles.label(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AdminBotLabel(email: peerEmail),
                      ],
                    ),
                    if (showTyping && typingAsync.value == true)
                      Text(
                        'typing...',
                        style: AppTextStyles.caption().copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else if (showOnline)
                      Text(
                        isOnline ? 'online' : 'offline',
                        style: AppTextStyles.caption().copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: !rtdbReady && !rtdbEmailAsync.isLoading
                ? Center(
                    child: Text(
                      AuthSession.isCurrentAccountSignedIn()
                          ? 'Could not start chat. Go back and try again.'
                          : 'Sign in again to send messages.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd(),
                    ),
                  )
                : messagesAsync.when(
              data: (messages) {
                final me = ref.watch(currentUserEmailProvider);
                final visible = iBlockedPeer
                    ? messages
                        .where(
                          (m) =>
                              m.senderEmail.trim().toLowerCase() != peerNorm,
                        )
                        .toList()
                    : messages;
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      iBlockedPeer
                          ? 'You have blocked this person. Their messages are hidden. '
                              'Unblock them in Settings to chat.'
                          : 'Start the conversation.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd(),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final message = visible[index];
                    final mine = message.senderEmail == me;
                    final scheme = Theme.of(context).colorScheme;
                    final timestampColor =
                        mine ? Colors.white70 : scheme.onSurfaceVariant;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MessageText(
                              text: message.text,
                              isCurrentUserBubble: mine,
                              messageStyle: AppTextStyles.bodyMd().copyWith(
                                color: mine ? Colors.white : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatMessageTime(message.createdAt),
                              style: AppTextStyles.caption().copyWith(
                                color: timestampColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load messages: $error')),
            ),
          ),
          if (iBlockedPeer)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'You have blocked this person. Unblock them in '
                      'Settings to send messages.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        onChanged: onChanged,
                        onSubmitted: (_) => unawaited(send()),
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: composerState.isLoading
                          ? null
                          : () => unawaited(send()),
                      child: composerState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

CommunityUser _fallbackPeerCommunityUser({
  required String peerEmail,
  required String peerDisplayName,
  String? peerPhotoUrl,
}) {
  return CommunityUser(
    email: peerEmail.toLowerCase().trim(),
    name: peerDisplayName,
    photoUrl: AppConstants.customProfilePhotoUrl(peerPhotoUrl),
    lastOnlineTime: 0,
    acceptingBattleInvites: true,
    isInBattleTill: null,
    appVersion: null,
    telegram: null,
    instagram: null,
    optionalContact: null,
    status: null,
    openChallengeTimestamp: null,
    openChallengeSubject: null,
  );
}

String _formatMessageTime(int millis) {
  if (millis <= 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  return DateFormat('hh:mm a').format(dt);
}

class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.text,
    required this.isCurrentUserBubble,
    required this.messageStyle,
  });

  final String text;
  final bool isCurrentUserBubble;
  final TextStyle messageStyle;

  static final RegExp _urlRegExp = RegExp(
    r'((https?:\/\/|www\.)[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final baseStyle = messageStyle;
    final scheme = Theme.of(context).colorScheme;
    final linkStyle = baseStyle.copyWith(
      color: isCurrentUserBubble ? Colors.white : scheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    final matches = _urlRegExp.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
      }
      final rawUrl = text.substring(m.start, m.end);
      final uri = _normalizeUri(rawUrl);
      spans.add(
        TextSpan(
          text: rawUrl,
          style: uri == null ? baseStyle : linkStyle,
          recognizer: uri == null
              ? null
              : (TapGestureRecognizer()
                ..onTap = () => _openUri(context, uri)),
        ),
      );
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }

  static Uri? _normalizeUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withScheme = trimmed.startsWith('www.')
        ? 'https://$trimmed'
        : trimmed;
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return uri;
  }

  static Future<void> _openUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.showText(context, 'Could not open link');
    }
  }
}
