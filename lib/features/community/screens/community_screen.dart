import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends HookConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Community', style: AppTextStyles.h3()),
          actions: [
            IconButton(
              tooltip: 'Random connect',
              icon: const Icon(Icons.casino_outlined),
              onPressed: () => context.push('/subject-test'),
            ),
            IconButton(
              tooltip: 'Visibility settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showSettings(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'Challengers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RecentTab(scheme: scheme),
            _ChallengersTab(scheme: scheme),
          ],
        ),
      ),
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
                    const SizedBox(height: AppSpacing.md),
                    if (sortedUsers.isEmpty)
                      Text(
                        'No users found right now.',
                        style: AppTextStyles.bodyMd(),
                      ),
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

class _ChallengersTab extends HookConsumerWidget {
  const _ChallengersTab({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengers = ref.watch(communityChallengersProvider);
    return challengers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load challengers', style: AppTextStyles.bodyMd()),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => ref.invalidate(communityChallengersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (users) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Open challenges floated in the last 24 hours.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (users.isEmpty)
            Text(
              'No open challenge floated in the last 24 hours.',
              style: AppTextStyles.bodyMd(),
            ),
          for (final user in users) ...[
            _UserTile(
              user: user,
              subtitleOverride: user.openChallengeSubject == null
                  ? null
                  : 'Subject: ${user.openChallengeSubject}',
              trailing: FilledButton(
                onPressed: () => context.push('/subject-test'),
                child: const Text('Challenge'),
              ),
              onTap: () => _showUserProfile(context, user),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onTap,
    this.trailing,
    this.subtitleOverride,
  });

  final CommunityUser user;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitleOverride;

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
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoUrl),
                radius: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.label()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitleOverride ??
                          '${_formatTime(user.lastOnlineTime)} · $statusText',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ...?(trailing != null ? [trailing!] : null),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showUserProfile(BuildContext context, CommunityUser user) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoUrl),
                  radius: 26,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(user.name, style: AppTextStyles.h3())],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if ((user.status ?? '').isNotEmpty)
              Text('Status: ${user.status}', style: AppTextStyles.bodyMd()),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if ((user.telegram ?? '').isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openExternal(
                      context,
                      'https://t.me/${user.telegram!.replaceAll('@', '')}',
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Telegram'),
                  ),
                if ((user.instagram ?? '').isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openExternal(
                      context,
                      'https://instagram.com/${user.instagram!.replaceAll('@', '')}',
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Instagram'),
                  ),
              ],
            ),
            if (!(user.acceptingBattleInvites))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'This user is not accepting battle invites right now.',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      );
    },
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visibility Settings', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                value: accepting,
                title: const Text('Accept battle invites'),
                onChanged: (v) => setState(() => accepting = v),
              ),
              SwitchListTile(
                value: showBattle,
                title: const Text('Show my in-battle status'),
                onChanged: (v) => setState(() => showBattle = v),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
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
            ],
          ),
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
