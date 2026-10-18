import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../chat/domain/chat_ids.dart';
import '../../chat/domain/entities/chat_message.dart';
import '../../chat/domain/entities/chat_runtime_config.dart';
import '../../chat/providers/chat_providers.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../../../l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Overlay state — activated by BattleResultScreen, cleared on dispose.
// ---------------------------------------------------------------------------

class BattleChatOverlayState {
  const BattleChatOverlayState({
    required this.opponentEmail,
    required this.opponentName,
    this.opponentPhotoUrl,
  });
  final String opponentEmail;
  final String opponentName;
  final String? opponentPhotoUrl;
}

class BattleChatOverlayNotifier extends StateNotifier<BattleChatOverlayState?> {
  BattleChatOverlayNotifier() : super(null);
  void activate(BattleChatOverlayState s) => state = s;
  void deactivate() => state = null;
}

final battleChatOverlayProvider =
    StateNotifierProvider<BattleChatOverlayNotifier, BattleChatOverlayState?>(
      (ref) => BattleChatOverlayNotifier(),
    );

class BattleChatSheetOpenNotifier extends StateNotifier<bool> {
  BattleChatSheetOpenNotifier() : super(false);
  void setOpen(bool value) => state = value;
}

final battleChatSheetOpenProvider =
    StateNotifierProvider<BattleChatSheetOpenNotifier, bool>(
      (ref) => BattleChatSheetOpenNotifier(),
    );

// ---------------------------------------------------------------------------
// Global host — lives in the root Stack (MaterialApp.router builder).
// ---------------------------------------------------------------------------

class BattleChatFabHost extends HookConsumerWidget {
  const BattleChatFabHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    useListenable(router.routerDelegate);
    useListenable(router.routeInformationProvider);
    final cfg = router.routerDelegate.currentConfiguration;
    final location = cfg.isEmpty
        ? router.routeInformationProvider.value.uri.path
        : router.state.uri.path;
    useEffect(() {
      if (location == '/') {
        // Defer provider mutation until after the current frame to avoid
        // "Tried to modify a provider while the widget tree was building."
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref.read(battleChatOverlayProvider.notifier).deactivate();
        });
      }
      return null;
    }, [location]);

    final overlay = ref.watch(battleChatOverlayProvider);
    final sheetOpen = ref.watch(battleChatSheetOpenProvider);
    if (overlay == null || sheetOpen) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    final isQuestionReviewRoute = location.startsWith('/history/');
    if (isQuestionReviewRoute) {
      return Positioned(
        right: AppSpacing.md,
        top: AppSpacing.xxxl * 2.5 + mq.padding.top,
        child: _BattleChatFab(overlay: overlay),
      );
    }
    return Positioned(
      right: AppSpacing.md,
      bottom: AppSpacing.md + mq.padding.bottom,
      child: _BattleChatFab(overlay: overlay),
    );
  }
}

// ---------------------------------------------------------------------------
// The FAB itself — pulse animation when there are unread messages.
// ---------------------------------------------------------------------------

class _BattleChatFab extends HookConsumerWidget {
  const _BattleChatFab({required this.overlay});
  final BattleChatOverlayState overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEmail = ref.watch(currentUserEmailProvider);
    if (myEmail == null) return const SizedBox.shrink();

    final chatId = useMemoized(
      () => ChatIds.chatIdForPair(myEmail, overlay.opponentEmail),
      [myEmail, overlay.opponentEmail],
    );

    final animController = useAnimationController(
      duration: const Duration(milliseconds: 700),
    );
    final pulseAnim = useMemoized(
      () => Tween<double>(begin: 1.0, end: 1.16).animate(
        CurvedAnimation(parent: animController, curve: Curves.easeInOut),
      ),
      [animController],
    );

    final threadsAsync = ref.watch(chatThreadsProvider);
    final unreadCount =
        threadsAsync.value
            ?.where((t) => t.chatId == chatId)
            .firstOrNull
            ?.unreadCount ??
        0;
    final hasUnread = unreadCount > 0;

    final wasUnread = useRef(false);
    useEffect(() {
      Timer? stopPulseTimer;
      if (hasUnread && !wasUnread.value) {
        animController.repeat(reverse: true);
        stopPulseTimer = Timer(const Duration(seconds: 2), () {
          animController.stop();
          animController.reset();
        });
      } else if (!hasUnread && wasUnread.value) {
        animController.stop();
        animController.reset();
      }
      wasUnread.value = hasUnread;
      return () => stopPulseTimer?.cancel();
    }, [hasUnread]);

    final scheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: pulseAnim,
      child: Material(
        elevation: 6,
        shape: const StadiumBorder(),
        color: hasUnread ? scheme.primary : scheme.surfaceContainerHigh,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => _openChat(context, chatId),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: hasUnread ? scheme.onPrimary : scheme.onSurface,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: scheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => _confirmCloseFab(context, ref),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 14, 12),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: hasUnread ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCloseFab(BuildContext context, WidgetRef ref) async {
    final anchor = rootNavigatorKey.currentContext;
    if (anchor == null) return;
    final shouldClose = await showDialog<bool>(
      context: anchor,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            dialogContext.l10n.bcfCloseTitle,
            style: AppTextStyles.h3(),
          ),
          content: Text(
            dialogContext.l10n.bcfCloseBody,
            style: AppTextStyles.bodyMd(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.l10n.commonClose),
            ),
          ],
        );
      },
    );
    if (shouldClose == true) {
      ref.read(battleChatOverlayProvider.notifier).deactivate();
    }
  }

  void _openChat(BuildContext context, String chatId) {
    final anchor = rootNavigatorKey.currentContext;
    if (anchor == null) return;
    final container = ProviderScope.containerOf(anchor, listen: false);
    unawaited(container.read(chatComposerProvider.notifier).markRead(chatId));
    container.read(battleChatSheetOpenProvider.notifier).setOpen(true);
    showModalBottomSheet<void>(
      context: anchor,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BattleChatSheet(
        chatId: chatId,
        opponentEmail: overlay.opponentEmail,
        opponentName: overlay.opponentName,
        opponentPhotoUrl: overlay.opponentPhotoUrl,
      ),
    ).whenComplete(() {
      unawaited(container.read(chatComposerProvider.notifier).markRead(chatId));
      container.read(battleChatSheetOpenProvider.notifier).setOpen(false);
    });
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet — half-screen chat window.
// ---------------------------------------------------------------------------

class _BattleChatSheet extends HookConsumerWidget {
  const _BattleChatSheet({
    required this.chatId,
    required this.opponentEmail,
    required this.opponentName,
    this.opponentPhotoUrl,
  });

  final String chatId;
  final String opponentEmail;
  final String opponentName;
  final String? opponentPhotoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sheetHeight = MediaQuery.of(context).size.height * 0.40;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final rtdbEmailAsync = ref.watch(chatRtdbEmailProvider);
    final rtdbEmail = rtdbEmailAsync.value;
    final rtdbReady = rtdbEmail != null && rtdbEmail.isNotEmpty;
    final messagesAsync = rtdbReady
        ? ref.watch(chatMessagesProvider(chatId))
        : const AsyncLoading<List<ChatMessage>>();
    final composerState = ref.watch(chatComposerProvider);
    final typingAsync = rtdbReady
        ? ref.watch(
            chatTypingProvider((chatId: chatId, peerEmail: opponentEmail)),
          )
        : const AsyncLoading<bool>();
    final presenceAsync = rtdbReady
        ? ref.watch(chatPresenceProvider(opponentEmail))
        : const AsyncLoading<bool>();
    final configAsync = ref.watch(chatRuntimeConfigProvider);
    final input = useTextEditingController();
    final scroll = useScrollController();
    final typingTimer = useRef<Timer?>(null);
    final messageCount = messagesAsync.value?.length ?? 0;

    useEffect(() {
      if (!rtdbReady) return null;
      unawaited(() async {
        await ref
            .read(chatComposerProvider.notifier)
            .ensureThread(chatId: chatId, peerEmail: opponentEmail);
        if (!context.mounted) return;
        ref.read(chatRuntimeConfigProvider.notifier).refresh();
        unawaited(ref.read(chatComposerProvider.notifier).markRead(chatId));
      }());
      return null;
    }, [chatId, opponentEmail, rtdbReady]);

    useEffect(() {
      if (messageCount <= 0) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scroll.hasClients) return;
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
      return null;
    }, [messageCount]);

    useEffect(() {
      final email = rtdbEmail;
      if (email == null || email.isEmpty) return null;
      final config =
          ref.read(chatRuntimeConfigProvider).value ??
          ChatRuntimeConfig.defaults;
      unawaited(
        ref
            .read(chatServiceProvider)
            .setOnline(currentUserEmail: email, isOnline: true, config: config),
      );
      return () {
        typingTimer.value?.cancel();
        unawaited(
          ref
              .read(chatComposerProvider.notifier)
              .setTyping(chatId: chatId, isTyping: false),
        );
        unawaited(
          ref
              .read(chatServiceProvider)
              .setOnline(
                currentUserEmail: email,
                isOnline: false,
                config: config,
              ),
        );
      };
    }, [chatId, rtdbEmail]);

    Future<void> send() async {
      final text = input.text.trim();
      if (text.isEmpty) return;
      typingTimer.value?.cancel();
      try {
        await ref
            .read(chatComposerProvider.notifier)
            .setTyping(chatId: chatId, isTyping: false);
        await ref
            .read(chatComposerProvider.notifier)
            .sendMessage(chatId: chatId, peerEmail: opponentEmail, text: text);
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
          AppToast.showText(context, context.l10n.bcfSendFailed(e.toString()));
        }
      }
    }

    void onChanged(String value) {
      if (!rtdbReady) return;
      final config = configAsync.value;
      if (config == null || !config.enableTypingIndicator) return;
      final isTyping = value.trim().isNotEmpty;
      unawaited(
        ref
            .read(chatComposerProvider.notifier)
            .setTyping(chatId: chatId, isTyping: isTyping),
      );
      typingTimer.value?.cancel();
      if (isTyping) {
        typingTimer.value = Timer(const Duration(seconds: 3), () {
          unawaited(
            ref
                .read(chatComposerProvider.notifier)
                .setTyping(chatId: chatId, isTyping: false),
          );
        });
      }
    }

    final isOnline = presenceAsync.value == true;
    final showOnline = configAsync.value?.enableOnlineIndicator == true;
    final showTyping = configAsync.value?.enableTypingIndicator == true;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SizedBox(
        height: sheetHeight,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    TappableCircularAvatar(
                      imageUrl: opponentPhotoUrl,
                      displayName: opponentName,
                      size: 36,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  opponentName,
                                  style: AppTextStyles.label(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AdminBotLabel(email: opponentEmail),
                            ],
                          ),
                          if (showTyping && typingAsync.value == true)
                            Text(
                              'typing...',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.primary,
                              ),
                            )
                          else if (showOnline)
                            Text(
                              isOnline ? 'online' : 'offline',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Messages
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    final me = ref.watch(currentUserEmailProvider);
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          context.l10n.bcfStartConv,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = message.senderEmail == me;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
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
                                Text(
                                  message.text,
                                  style: AppTextStyles.bodyMd().copyWith(
                                    color: mine ? Colors.white : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.createdAt),
                                  style: AppTextStyles.caption().copyWith(
                                    color: mine
                                        ? Colors.white70
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(context.l10n.bcfLoadFailed(e.toString())),
                  ),
                ),
              ),
              // Input bar
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
                          decoration: InputDecoration(
                            hintText: context.l10n.bcfHint,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(int millis) {
  if (millis <= 0) return '';
  return DateFormat(
    'hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}
