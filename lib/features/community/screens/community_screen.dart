import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../battle/domain/entities/battle_invite_target.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends HookConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Community', style: AppTextStyles.h3()),
        actions: [
          IconButton(
            tooltip: 'Random connect',
            icon: const Icon(Icons.casino_outlined),
            onPressed: () => _showRandomConnectSheet(context),
          ),
          IconButton(
            tooltip: 'Visibility settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: _RecentTab(scheme: scheme),
    );
  }
}

class _RecentTab extends HookConsumerWidget {
  const _RecentTab({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(communityRecentUsersProvider);
    final notifier = ref.read(communityRecentUsersProvider.notifier);
    final lastRefreshedAt = notifier.lastRefreshedAt;
    return recent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load recent users', style: AppTextStyles.bodyMd()),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => ref.invalidate(communityRecentUsersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (users) {
        final sortedUsers = [...users]
          ..sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(communityRecentUsersProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Tap a user to view profile and social links.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (lastRefreshedAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Last refreshed: ${DateFormat('hh:mm a').format(lastRefreshedAt)}',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (sortedUsers.isEmpty) ...[
                      Text(
                        'No users found in the latest window.',
                        style: AppTextStyles.bodyMd(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pull down to refresh or tap Load More for older active users.',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    for (final user in sortedUsers) ...[
                      _UserTile(
                        user: user,
                        onTap: () => _showUserProfile(context, user),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: notifier.hasMore ? notifier.loadMore : null,
                    child: Text(
                      notifier.hasMore ? 'Load More' : 'No More Users',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onTap,
  });

  final CommunityUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusText = user.isInBattle ? 'fighting a battle' : 'available';
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              TappableCircularAvatar(
                imageUrl: user.photoUrl,
                displayName: user.name,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.label()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_formatTime(user.lastOnlineTime)} · $statusText',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showUserProfile(BuildContext context, CommunityUser user) async {
  bool isBlocked = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final scheme = Theme.of(context).colorScheme;
        final isSelf = false;
        final canInviteBattle =
            !user.isInBattle &&
            user.acceptingBattleInvites &&
            !isBlocked &&
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
                      displayName: user.name,
                      size: 76,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: AppTextStyles.h3()),
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
                        onPressed: () {
                          setState(() => isBlocked = !isBlocked);
                          _showComingSoonSnackBar(context, 'Block/Unblock');
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
                                        user.photoUrl.trim().isEmpty
                                            ? null
                                            : user.photoUrl,
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isBlocked || isSelf
                        ? null
                        : () =>
                              _showComingSoonSnackBar(context, 'Send Message'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Send Message'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                          'Last online: ${_formatTime(user.lastOnlineTime)}',
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
                            : () => _openExternal(
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
                            : () => _openExternal(
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

Future<void> _showSettings(BuildContext context, WidgetRef ref) async {
  final state =
      ref.read(communitySettingsProvider).value ??
      const CommunitySettingsState(
        acceptingBattleInvites: true,
        showInBattleStatus: true,
      );
  bool accepting = state.acceptingBattleInvites;
  bool showBattle = state.showInBattleStatus;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Text(
                  'Set Visibility',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3().copyWith(color: scheme.onPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Battle Invites', style: AppTextStyles.label()),
              ),
              const SizedBox(height: AppSpacing.xs),
              SwitchListTile(
                value: accepting,
                title: const Text('Accept battle invites'),
                subtitle: Text(
                  accepting
                      ? 'You are receiving battle invites.'
                      : 'You are not receiving battle invites.',
                  style: AppTextStyles.caption(),
                ),
                onChanged: (v) => setState(() => accepting = v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: showBattle,
                title: const Text('Show my in-battle status'),
                subtitle: Text(
                  showBattle
                      ? 'Others can see when you are in a battle.'
                      : 'Others cannot see your in-battle status.',
                  style: AppTextStyles.caption(),
                ),
                onChanged: (v) => setState(() => showBattle = v),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Keep your profile updated so others can connect with you even outside UPSC Wars.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        await ref
                            .read(communitySettingsProvider.notifier)
                            .updateSettings(
                              acceptingBattleInvites: accepting,
                              showInBattleStatus: showBattle,
                            );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save settings'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showRandomConnectSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tap below for Random Battle Connect',
              style: AppTextStyles.bodyMd(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/battle/config');
                },
                child: const Text('Random Connect'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _openExternal(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link')));
  }
}

String _formatTime(int millis) {
  if (millis <= 0) return 'unknown';
  return DateFormat(
    'dd MMM, hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}

void _showComingSoonSnackBar(BuildContext context, String action) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$action flow will be connected next.')),
  );
}
