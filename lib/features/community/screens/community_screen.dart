import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../../shared/widgets/unread_pulse_wrapper.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../chat/providers/chat_providers.dart';
import '../../home/providers/auth_providers.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';
import '../providers/open_challenge_providers.dart';
import 'community_qotd_tab.dart';
import '../widgets/community_user_profile_sheet.dart';
import '../widgets/open_challenge_community_section.dart';

export '../widgets/community_user_profile_sheet.dart'
    show showCommunityUserProfileSheet;

class CommunityScreen extends HookConsumerWidget {
  const CommunityScreen({super.key, this.initialTabIndex = 0});

  /// 0 = Recent online, 1 = Open challenge, 2 = QOTD.
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final safeIndex = initialTabIndex.clamp(0, 2);
    final tabController = useTabController(
      initialLength: 3,
      initialIndex: safeIndex,
    );
    final chatHasUnread = ref.watch(chatInboxHasUnreadProvider);
    return PopToShellHomeScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Community', style: AppTextStyles.h3()),
          bottom: TabBar(
            controller: tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Recent online'),
              Tab(text: 'Open challenge'),
              Tab(text: 'QOTD'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Chats',
              onPressed: () => context.push('/chats'),
              icon: UnreadPulseWrapper(
                active: chatHasUnread,
                scheme: scheme,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      chatHasUnread ? Icons.chat_rounded : Icons.chat_outlined,
                      color: chatHasUnread ? scheme.primary : null,
                    ),
                    if (chatHasUnread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
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
        body: TabBarView(
          controller: tabController,
          children: [
            _RecentTab(scheme: scheme),
            const _OpenChallengesTab(),
            const CommunityQotdTab(),
          ],
        ),
      ),
    );
  }
}

class _OpenChallengesTab extends ConsumerWidget {
  const _OpenChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(openChallengesListProvider);
      },
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('community_open_challenges_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        child: const OpenChallengeCommunitySection(),
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
    final lastRefreshedAt = notifier.lastRefreshedAt;
    final currentUserEmail =
        ref.watch(authStateChangesProvider).asData?.value?.email?.toLowerCase();
    return recent.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              'Recent online',
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading recent users…',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
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
                  onPressed: null,
                  child: Text(
                    notifier.hasMore ? 'Load More' : 'No More Users',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (error, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              'Recent online',
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
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
        ],
      ),
      data: (users) {
        final sortedUsers = [...users]
          ..sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                'Recent online',
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(communityRecentUsersProvider.notifier)
                      .refresh();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
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
                        onTap: () => showCommunityUserProfileSheet(
                          context,
                          ref,
                          user,
                          currentUserEmail: currentUserEmail,
                        ),
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
                      '${formatCommunityProfileLastOnline(user.lastOnlineTime)} · $statusText',
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
                    'Keep your profile updated so others can connect with you even outside ${AppConstants.appDisplayName}.',
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
