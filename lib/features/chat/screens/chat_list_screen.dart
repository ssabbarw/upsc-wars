import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../domain/entities/chat_thread_route_payload.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends HookConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(filteredChatThreadsProvider);
    final me = ref.watch(currentUserEmailProvider);
    final scheme = Theme.of(context).colorScheme;
    void leaveList() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/community');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        leaveList();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chats', style: AppTextStyles.h3()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: leaveList,
          ),
        ),
        body: threadsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(chatThreadsProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (threads) {
            if (threads.isEmpty) {
              return Center(
                child: Text(
                  'No chats yet',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            final peerNames =
                ref.watch(chatPeerDisplayNamesProvider).value ?? const {};
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: threads.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final peerEmail = peerEmailForThread(thread, me);
                final peerName = peerNames[peerEmail] ?? 'UPSC Warrior';
                final subtitle =
                    thread.lastMessageText ?? 'Start the conversation';
                final unread = thread.unreadCount;
                return Material(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      context.push(
                        '/chat/${thread.chatId}',
                        extra: ChatThreadRoutePayload(
                          peerEmail: peerEmail,
                          peerDisplayName: peerName,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          TappableCircularAvatar(
                            imageUrl: null,
                            displayName: peerName,
                            size: 42,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        peerName,
                                        style: AppTextStyles.label(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    AdminBotLabel(email: peerEmail),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: unread > 0
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(
                                  thread.lastMessageAt ?? thread.updatedAt,
                                ),
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _formatTime(int millis) {
  if (millis <= 0) return '';
  return DateFormat(
    'dd MMM, hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}
