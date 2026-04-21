import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../community/domain/entities/community_user.dart';
import '../../community/providers/community_providers.dart';
import '../../community/providers/user_block_providers.dart';
import '../../community/screens/community_screen.dart';
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
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    final composerState = ref.watch(chatComposerProvider);
    final typingAsync = ref.watch(
      chatTypingProvider((chatId: chatId, peerEmail: peerEmail)),
    );
    final presenceAsync = ref.watch(chatPresenceProvider(peerEmail));
    final configAsync = ref.watch(chatRuntimeConfigProvider);
    final input = useTextEditingController();
    final scroll = useScrollController();
    final typingTimer = useRef<Timer?>(null);
    final peerNorm = peerEmail.trim().toLowerCase();
    final iBlockedPeer = ref.watch(isPeerBlockedProvider(peerNorm));

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(chatRuntimeConfigProvider.notifier).refresh();
        unawaited(ref.read(chatComposerProvider.notifier).markRead(chatId));
      });
      return null;
    }, [chatId]);

    useEffect(() {
      final current = ref.read(currentUserEmailProvider);
      if (current == null) return null;
      final config =
          ref.read(chatRuntimeConfigProvider).value ?? ChatRuntimeConfig.defaults;
      final chatService = ref.read(chatServiceProvider);
      final composer = ref.read(chatComposerProvider.notifier);
      unawaited(
        chatService.setOnline(
          currentUserEmail: current,
          isOnline: true,
          config: config,
        ),
      );
      return () {
        typingTimer.value?.cancel();
        unawaited(
          composer.setTyping(chatId: chatId, isTyping: false),
        );
        unawaited(
          chatService.setOnline(
            currentUserEmail: current,
            isOnline: false,
            config: config,
          ),
        );
      };
    }, [chatId]);

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message failed to send: $e'),
            ),
          );
        }
      }
    }

    void onChanged(String value) {
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
                    Text(peerDisplayName, style: AppTextStyles.label()),
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
            child: messagesAsync.when(
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
                              'Unblock them from Community to chat.'
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
                      'You have blocked this person. Unblock them from '
                      'Community to send messages.',
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
  final photo = peerPhotoUrl?.trim() ?? '';
  return CommunityUser(
    email: peerEmail.toLowerCase().trim(),
    name: peerDisplayName,
    photoUrl: photo.isNotEmpty
        ? photo
        : AppConstants.defaultProfilePhotoUrl,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }
}
