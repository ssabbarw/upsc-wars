import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../battle/domain/entities/battle_invite_target.dart';
import '../../chat/domain/chat_ids.dart';
import '../../chat/domain/entities/chat_thread_route_payload.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';
import '../providers/user_block_providers.dart';

Future<void> openCommunityExternalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link')));
  }
}

String formatCommunityProfileLastOnline(int millis) {
  if (millis <= 0) return 'unknown';
  return DateFormat(
    'dd MMM, hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}

Future<void> showCommunityUserProfileSheet(
  BuildContext context,
  WidgetRef ref,
  CommunityUser user, {
  String? currentUserEmail,
  bool hideSendMessage = false,
  bool confirmBlockClosesChat = false,
  VoidCallback? onBlockedFromChat,
}) async {
  final blockedInitially = ref
      .read(blockedUserEmailsProvider)
      .maybeWhen(
        data: (s) => s.contains(user.email.toLowerCase()),
        orElse: () => false,
      );
  var isBlocked = blockedInitially;
  var guestHasBlockedMe = false;
  final meNorm = currentUserEmail?.toLowerCase().trim();
  final peerNorm = user.email.toLowerCase();
  if (meNorm != null && meNorm.isNotEmpty && meNorm != peerNorm) {
    try {
      guestHasBlockedMe = await ref
          .read(communityRepositoryProvider)
          .isUserBlocked(ownerEmail: peerNorm, otherEmail: meNorm);
    } catch (_) {
      guestHasBlockedMe = false;
    }
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final scheme = Theme.of(context).colorScheme;
        final displayLabel = displayNameForViewer(
          name: user.name,
          viewerEmail: meNorm,
          subjectEmail: user.email,
        );
        final isSelf =
            meNorm != null &&
            meNorm.isNotEmpty &&
            meNorm == user.email.toLowerCase();
        final canInviteBattle =
            !user.isInBattle &&
            user.acceptingBattleInvites &&
            !isBlocked &&
            !guestHasBlockedMe &&
            !isSelf;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TappableCircularAvatar(
                      imageUrl: user.photoUrl,
                      displayName: displayLabel,
                      size: 76,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayLabel, style: AppTextStyles.h3()),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.isInBattle ? 'fighting a battle' : 'available',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSelf
                            ? null
                            : () async {
                                final me = currentUserEmail;
                                if (me == null || me.isEmpty) return;
                                final repo = ref.read(
                                  communityRepositoryProvider,
                                );
                                final target = user.email.toLowerCase();
                                final nextBlocked = !isBlocked;
                                if (nextBlocked &&
                                    confirmBlockClosesChat &&
                                    context.mounted) {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Block this user?'),
                                      content: const Text(
                                        'This will close this chat and block '
                                        'them.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(true),
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                }
                                try {
                                  await repo.setUserBlocked(
                                    ownerEmail: me,
                                    otherEmail: target,
                                    blocked: nextBlocked,
                                  );
                                  if (nextBlocked && confirmBlockClosesChat) {
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    onBlockedFromChat?.call();
                                    return;
                                  }
                                  setState(() => isBlocked = nextBlocked);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          nextBlocked
                                              ? 'You will not see messages or '
                                                    'battle invites from '
                                                    '${user.name}.'
                                              : '${user.name} has been unblocked.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not update block: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(
                          isBlocked
                              ? Icons.lock_open_outlined
                              : Icons.block_outlined,
                        ),
                        label: Text(isBlocked ? 'Unblock' : 'Block'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: !canInviteBattle
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                context.push(
                                  '/battle/config',
                                  extra: BattleInviteTarget(
                                    email: user.email.toLowerCase(),
                                    displayName: user.name,
                                    photoUrl:
                                        AppConstants.profileImageUrlOrDefault(
                                          user.photoUrl,
                                        ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.sports_martial_arts_outlined),
                        label: const Text('Invite'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!hideSendMessage) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isBlocked || isSelf
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              final me = currentUserEmail;
                              if (me == null || me.isEmpty) return;
                              final chatId = ChatIds.chatIdForPair(
                                me,
                                user.email,
                              );
                              context.push(
                                '/chat/$chatId',
                                extra: ChatThreadRoutePayload(
                                  peerEmail: user.email.toLowerCase(),
                                  peerDisplayName: user.name,
                                  peerPhotoUrl:
                                      AppConstants.profileImageUrlOrDefault(
                                        user.photoUrl,
                                      ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Send Message'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: AppTextStyles.label()),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (user.status ?? '').trim().isEmpty
                            ? 'Hey there! I am a UPSC Warrior.'
                            : user.status!,
                        style: AppTextStyles.bodySm(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Last online: ${formatCommunityProfileLastOnline(user.lastOnlineTime)}',
                          style: AppTextStyles.bodySm(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (user.instagram ?? '').isEmpty
                            ? null
                            : () => openCommunityExternalUrl(
                                context,
                                'https://instagram.com/${user.instagram!.replaceAll('@', '')}',
                              ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(
                          (user.instagram ?? '').isEmpty
                              ? 'Instagram'
                              : user.instagram!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (user.telegram ?? '').isEmpty
                            ? null
                            : () => openCommunityExternalUrl(
                                context,
                                'https://t.me/${user.telegram!.replaceAll('@', '')}',
                              ),
                        icon: const Icon(Icons.send_outlined),
                        label: Text(
                          (user.telegram ?? '').isEmpty
                              ? 'Telegram'
                              : user.telegram!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
