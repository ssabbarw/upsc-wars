import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/analytics_audience.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/notifications/notification_prompt_policy.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/providers/super_user_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../shared/widgets/push_denied_banner.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../../shared/widgets/unread_pulse_wrapper.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../chat/providers/chat_providers.dart';
import '../../home/providers/auth_providers.dart';
import '../domain/community_bot.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';
import '../providers/open_challenge_providers.dart';
import 'community_qotd_tab.dart';
import '../widgets/community_user_profile_sheet.dart';
import '../widgets/open_challenge_community_section.dart';
import '../widgets/admin_bot_label.dart';

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
    useEffect(() {
      unawaited(
        BattleMessagingService.maybePromptAfterScreenSettles(
          context: context,
          surface: NotificationPromptSurface.community,
          source: 'community_screen',
        ),
      );
      return null;
    }, const []);
    return PopToShellHomeScope(
      onInnerBack: () {
        if (tabController.index == 0) return false;
        tabController.animateTo(0);
        return true;
      },
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: const PushDeniedBanner(),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _RecentTab(scheme: scheme),
                  const _OpenChallengesTab(),
                  const CommunityQotdTab(),
                ],
              ),
            ),
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
    final currentUserEmail = ref
        .watch(authStateChangesProvider)
        .asData
        ?.value
        ?.email
        ?.toLowerCase();
    final scroll = useScrollController();

    useEffect(() {
      void onScroll() {
        if (!scroll.hasClients) return;
        final pos = scroll.position;
        if (pos.pixels >= pos.maxScrollExtent - 280) {
          notifier.loadMore();
        }
      }

      scroll.addListener(onScroll);
      return () => scroll.removeListener(onScroll);
    }, [scroll]);

    useEffect(() {
      final page = recent.asData?.value;
      if (page == null || !page.hasMore || page.isLoadingMore) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scroll.hasClients) return;
        if (scroll.position.extentAfter < 280) {
          notifier.loadMore();
        }
      });
      return null;
    }, [recent]);

    if (recent.isLoading) {
      return _RecentOnlineLoading(scheme: scheme);
    }
    return recent.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => _RecentOnlineLoading(scheme: scheme),
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
              style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load recent users',
                  style: AppTextStyles.bodyMd(),
                ),
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
      data: (page) {
        final sortedUsers = [...page.users]
          ..sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
        final lastRefreshedAt = page.lastRefreshedAt;

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
                style: AppTextStyles.label().copyWith(color: scheme.onSurface),
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
                  controller: scroll,
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
                    _AdminRecentsSummary(users: sortedUsers),
                    const SizedBox(height: AppSpacing.md),
                    if (sortedUsers.isEmpty) ...[
                      Text(
                        'No users found in the latest window.',
                        style: AppTextStyles.bodyMd(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pull down to refresh.',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    for (final user in sortedUsers) ...[
                      _UserTile(
                        user: user,
                        currentUserEmail: currentUserEmail,
                        onTap: () => showCommunityUserProfileSheet(
                          context,
                          ref,
                          user,
                          currentUserEmail: currentUserEmail,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (page.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (!page.hasMore)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.lg,
                        ),
                        child: Center(
                          child: Text(
                            "That's all",
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentOnlineLoading extends StatelessWidget {
  const _RecentOnlineLoading({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
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
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                _RecentLoadingCaption(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminRecentsSummary extends ConsumerWidget {
  const _AdminRecentsSummary({required this.users});

  final List<CommunityUser> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSuperUserProvider)) {
      return const SizedBox.shrink();
    }
    var real = 0;
    var bots = 0;
    for (final user in users) {
      if (AnalyticsAudience.isReservedBotEmail(user.email)) {
        bots += 1;
      } else {
        real += 1;
      }
    }
    final botIndex =
        ref.watch(trafficBotIndexProvider).asData?.value ?? TrafficBotIndex.empty;
    final vsBots = botIndex.warPeopleLast24h;
    final finished = botIndex.battleCompletedPeopleLast24h;
    final realLabel = real == 1 ? '1 real user' : '$real real users';
    final botLabel = bots == 1 ? '1 bot' : '$bots bots';
    final warLabel = vsBots == 1
        ? '1 person joined vs bots (24h)'
        : '$vsBots people joined vs bots (24h)';
    final doneLabel = finished == 1
        ? '1 finished'
        : '$finished finished';
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        '$realLabel · $botLabel · $warLabel · $doneLabel',
        style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _RecentLoadingCaption extends StatelessWidget {
  const _RecentLoadingCaption();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'Loading recent users…',
      style: AppTextStyles.bodySm().copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.currentUserEmail,
    required this.onTap,
  });

  final CommunityUser user;
  final String? currentUserEmail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nameLabel = displayNameForViewer(
      name: user.name,
      viewerEmail: currentUserEmail,
      subjectEmail: user.email,
    );
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
                displayName: nameLabel,
                size: 40,
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
                            nameLabel,
                            style: AppTextStyles.label(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AdminBotLabel(email: user.email),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatCommunityProfileLastOnline(user.lastOnlineTime),
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
                          AppToast.showText(context, 'Failed to save settings');
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ),
              SizedBox(height: paddedBottomInset(context, AppSpacing.lg)),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showRandomConnectSheet(BuildContext context) async {
  final router = GoRouter.of(context);
  final start = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          paddedBottomInset(sheetContext, AppSpacing.lg),
        ),
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
                onPressed: () => Navigator.of(
                  sheetContext,
                  rootNavigator: true,
                ).pop(true),
                child: const Text('Random Connect'),
              ),
            ),
          ],
        ),
      );
    },
  );
  if (start != true) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.push('/battle/config');
  });
}
