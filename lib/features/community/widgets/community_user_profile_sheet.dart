import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/debug/upsc_wars_trace.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../battle/domain/entities/battle_invite_target.dart';
import '../../chat/domain/chat_ids.dart';
import '../../chat/domain/entities/chat_thread_route_payload.dart';
import '../../home/providers/auth_providers.dart';
import '../domain/entities/community_user.dart';
import '../providers/user_block_providers.dart';
import '../widgets/admin_bot_label.dart';

Future<void> openCommunityExternalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    AppToast.showText(context, 'Could not open link');
  }
}

String formatCommunityProfileLastOnline(int millis) {
  if (millis <= 0) return 'unknown';
  return DateFormat(
    'dd MMM, hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}

sealed class _CommunityProfileNav {
  const _CommunityProfileNav();
}

final class _CommunityProfileInviteNav extends _CommunityProfileNav {
  const _CommunityProfileInviteNav(this.target);
  final BattleInviteTarget target;
}

final class _CommunityProfileMessageNav extends _CommunityProfileNav {
  const _CommunityProfileMessageNav({
    required this.chatId,
    required this.payload,
  });
  final String chatId;
  final ChatThreadRoutePayload payload;
}

String? _signedInEmail(WidgetRef ref, [String? passed]) {
  return AuthSession.normalizeEmail(passed) ??
      AuthSession.emailOf(ref.read(authStateChangesProvider).asData?.value) ??
      AuthSession.currentEmail();
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
  final meNorm = _signedInEmail(ref, currentUserEmail);
  final hasCurrentUser = meNorm != null && meNorm.isNotEmpty;
  upscWarsTrace(
    'CommunityProfile sheet open hideSendMessage=$hideSendMessage '
    'hasCurrentUser=$hasCurrentUser blockedInitially=$blockedInitially '
    'isSelf=${hasCurrentUser && meNorm == user.email.toLowerCase()} '
    'peerEmailLen=${user.email.length}',
  );
  if (!context.mounted) {
    upscWarsTrace('CommunityProfile sheet aborted: context unmounted before show');
    return;
  }
  final router = GoRouter.of(context);
  final action = await showModalBottomSheet<_CommunityProfileNav>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final scheme = Theme.of(sheetContext).colorScheme;
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
            !isSelf;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              paddedBottomInset(sheetContext, AppSpacing.xxl),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayLabel,
                                  style: AppTextStyles.h3(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AdminBotLabel(email: user.email),
                            ],
                          ),
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
                                final me = _signedInEmail(ref, currentUserEmail);
                                if (me == null || me.isEmpty) return;
                                final target = user.email.toLowerCase();
                                final nextBlocked = !isBlocked;
                                if (nextBlocked &&
                                    confirmBlockClosesChat &&
                                    sheetContext.mounted) {
                                  final confirmed = await showDialog<bool>(
                                    context: sheetContext,
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
                                  await ref
                                      .read(blockedUserEmailsProvider.notifier)
                                      .setBlocked(
                                        otherEmail: target,
                                        blocked: nextBlocked,
                                      );
                                  if (nextBlocked && confirmBlockClosesChat) {
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                    onBlockedFromChat?.call();
                                    return;
                                  }
                                  setState(() => isBlocked = nextBlocked);
                                  if (sheetContext.mounted) {
                                    AppToast.showText(
                                      sheetContext,
                                      nextBlocked
                                          ? 'You will not see messages or battle invites from ${user.name}.'
                                          : '${user.name} has been unblocked.',
                                    );
                                  }
                                } catch (e) {
                                  if (sheetContext.mounted) {
                                    AppToast.showText(
                                      sheetContext,
                                      'Could not update block: $e',
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
                                Navigator.of(
                                  sheetContext,
                                  rootNavigator: true,
                                ).pop(
                                  _CommunityProfileInviteNav(
                                    BattleInviteTarget(
                                      email: user.email.toLowerCase(),
                                      displayName: user.name,
                                      photoUrl:
                                          AppConstants.customProfilePhotoUrl(
                                            user.photoUrl,
                                          ),
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
                          : () async {
                              try {
                                var me = _signedInEmail(ref, currentUserEmail);
                                upscWarsTrace(
                                  'CommunityProfile Send Message tapped '
                                  'hasMe=${me != null} '
                                  'accountSignedIn=${AuthSession.isCurrentAccountSignedIn()} '
                                  'peerEmailLen=${user.email.length}',
                                );
                                if (me == null &&
                                    !AuthSession.isCurrentAccountSignedIn()) {
                                  upscWarsTrace(
                                    'CommunityProfile Send Message prompting sign-in',
                                  );
                                  final signedIn = await ensureAccountSignedIn(
                                    context: sheetContext,
                                    ref: ref,
                                    reason: 'Sign in to send messages.',
                                  );
                                  if (!sheetContext.mounted) return;
                                  me = _signedInEmail(ref);
                                  if (!signedIn || me == null) {
                                    upscWarsTrace(
                                      'CommunityProfile Send Message aborted '
                                      'after sign-in signedIn=$signedIn '
                                      'hasMe=${me != null}',
                                    );
                                    if (me == null && sheetContext.mounted) {
                                      AppToast.showText(
                                        sheetContext,
                                        'Could not start chat. Please sign in again.',
                                      );
                                    }
                                    return;
                                  }
                                }
                                if (me == null || me.isEmpty) {
                                  upscWarsTrace(
                                    'CommunityProfile Send Message aborted: '
                                    'missing current user email',
                                  );
                                  if (sheetContext.mounted) {
                                    AppToast.showText(
                                      sheetContext,
                                      'Could not start chat. Please sign in again.',
                                    );
                                  }
                                  return;
                                }
                                if (me == user.email.toLowerCase()) {
                                  upscWarsTrace(
                                    'CommunityProfile Send Message aborted: self',
                                  );
                                  return;
                                }
                                final chatId = ChatIds.chatIdForPair(
                                  me,
                                  user.email,
                                );
                                upscWarsTrace(
                                  'CommunityProfile Send Message popping '
                                  'chatIdLen=${chatId.length}',
                                );
                                Navigator.of(
                                  sheetContext,
                                  rootNavigator: true,
                                ).pop(
                                  _CommunityProfileMessageNav(
                                    chatId: chatId,
                                    payload: ChatThreadRoutePayload(
                                      peerEmail: user.email.toLowerCase(),
                                      peerDisplayName: user.name,
                                      peerPhotoUrl:
                                          AppConstants.customProfilePhotoUrl(
                                            user.photoUrl,
                                          ),
                                    ),
                                  ),
                                );
                              } catch (e, st) {
                                upscWarsTrace(
                                  'CommunityProfile Send Message tap failed',
                                  error: e,
                                  stackTrace: st,
                                );
                                if (sheetContext.mounted) {
                                  AppToast.showText(
                                    sheetContext,
                                    'Could not start chat: $e',
                                  );
                                }
                              }
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
                                sheetContext,
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
                                sheetContext,
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
  if (action == null) {
    upscWarsTrace('CommunityProfile sheet dismissed without action');
    return;
  }
  upscWarsTrace('CommunityProfile sheet action=${action.runtimeType}');
  // Push after the sheet route is gone, from the captured router (root), so a
  // shell-tab switch cannot swallow the next screen.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      switch (action) {
        case _CommunityProfileInviteNav(:final target):
          upscWarsTrace('CommunityProfile navigating to /battle/config');
          await router.push('/battle/config', extra: target);
        case _CommunityProfileMessageNav(:final chatId, :final payload):
          upscWarsTrace(
            'CommunityProfile navigating to /chat '
            'chatIdLen=${chatId.length} peerEmailLen=${payload.peerEmail.length}',
          );
          await router.push('/chat/$chatId', extra: payload);
          upscWarsTrace('CommunityProfile chat push completed');
      }
    } catch (e, st) {
      upscWarsTrace(
        'CommunityProfile navigation failed action=${action.runtimeType}',
        error: e,
        stackTrace: st,
      );
    }
  });
}
