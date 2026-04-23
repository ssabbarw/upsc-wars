import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../analytics/analytics_route_observer.dart';
import '../debug/upsc_wars_trace.dart';
import '../services/deferred_push_permission_coordinator.dart';
import '../config/feature_flags.dart';
import '../../features/bookmarks/screens/bookmarks_screen.dart';
import '../../features/battle/domain/entities/battle_result_payload.dart';
import '../../features/battle/domain/entities/battle_invite_target.dart';
import '../../features/battle/screens/battle_config_screen.dart';
import '../../features/battle/screens/battle_join_screen.dart';
import '../../features/battle/screens/battle_result_screen.dart';
import '../../features/battle/screens/battle_test_screen.dart';
import '../../features/battle/screens/battle_waiting_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/history/screens/session_review_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/post_qotd_flow_screen.dart';
import '../../features/community/screens/community_connect_screen.dart';
import '../../features/community/screens/open_challenge_detail_screen.dart';
import '../../features/community/screens/open_challenge_pick_subject_screen.dart';
import '../../features/community/providers/community_providers.dart';
import '../../features/community/providers/open_challenge_providers.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_thread_screen.dart';
import '../../features/chat/domain/entities/chat_thread_route_payload.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_flow_screen.dart';
import '../../features/notifications/screens/long_html_notification_screen.dart';
import '../../features/pyq/screens/pyq_year_packs_screen.dart';
import '../../features/home/screens/profile_screen.dart';
import '../../features/home/screens/settings_screen.dart';
import '../../features/home/screens/progress_screen.dart';
import '../../features/internal/screens/feature_health_screen.dart';
import '../../features/home/providers/auth_providers.dart';
import '../../features/results/screens/confidence_tier_review_screen.dart';
import '../../features/results/screens/danger_zone_review_screen.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/revision_queue/screens/revision_queue_screen.dart';
import '../../features/revision_queue/screens/revision_mode_screen.dart';
import '../../features/subject_detail/screens/subject_detail_screen.dart';
import '../../features/subject_detail/screens/topics_list_screen.dart';
import '../../features/subject_test/screens/subject_test_screen.dart';
import '../../features/test_engine/screens/test_engine_screen.dart';
import '../../features/topic_test/screens/topic_test_screen.dart';
import '../../features/weak_areas/screens/weak_areas_hub_screen.dart';
import '../../features/weak_areas/screens/concept_detail_screen.dart'
    show SubTopicDetailScreen;
import '../../features/weak_areas/screens/trap_patterns_screen.dart';
import '../../features/weak_areas/screens/trap_pattern_detail_screen.dart';
import '../../shared/widgets/google_login_bottom_sheet.dart';
import '../../shared/widgets/unread_pulse_wrapper.dart';
import '../providers/app_bootstrap.dart';
import '../providers/kill_switch_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  ref.watch(appBootstrapProvider).requireValue;
  final shellHasCommunity = FeatureFlags.communityTab;
  final redirectRefresh = _CommunityTabRedirectRefresh();
  ref.onDispose(redirectRefresh.dispose);
  ref.listen(communityTabRemoteEnabledProvider, (_, _) {
    redirectRefresh.notify();
  });

  bool communityTabVisibleForRedirect() {
    if (!shellHasCommunity) return false;
    return ref
        .read(communityTabRemoteEnabledProvider)
        .maybeWhen(data: (v) => v, orElse: () => true);
  }

  final shellBranches = <StatefulShellBranch>[
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/history',
          name: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/progress',
          name: 'progress',
          builder: (context, state) => const ProgressScreen(),
        ),
      ],
    ),
    if (FeatureFlags.communityTab)
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              final openChallenge =
                  tab == 'open_challenge' || tab == 'open-challenge';
              return CommunityScreen(initialTabIndex: openChallenge ? 1 : 0);
            },
          ),
        ],
      ),
  ];
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: redirectRefresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      if (!communityTabVisibleForRedirect() &&
          state.matchedLocation == '/community') {
        upscWarsTrace(
          'GoRouter redirect uri=${state.uri} matched=${state.matchedLocation} '
          '-> /',
        );
        return '/';
      }
      return null;
    },
    observers: [
      AnalyticsRouteObserver(ref),
      UpscWarsRouteTraceObserver(),
    ],
    routes: [
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: shellBranches,
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/feature-health',
        name: 'feature_health',
        builder: (context, state) => const FeatureHealthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/notification/long-html',
        builder: (context, state) => const LongHtmlNotificationScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/connect',
        builder: (context, state) {
          return CommunityConnectScreen(selectedUser: state.extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/qotd/post',
        builder: (context, state) => const PostQotdFlowScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/qotd/explanation',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SingleQuestionReviewArgs) {
            return const Scaffold(
              body: Center(child: Text('Invalid QOTD explanation navigation')),
            );
          }
          return SingleQuestionReviewScreen(args: extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/open-challenges/new/subject',
        builder: (context, state) => const OpenChallengePickSubjectScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/open-challenges/:challengeId',
        builder: (context, state) => OpenChallengeDetailScreen(
          challengeId: state.pathParameters['challengeId']!,
          backToCommunityOpenTab:
              state.uri.queryParameters['origin'] == 'accept_flow',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/chat/:chatId',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! ChatThreadRoutePayload) {
            return const Scaffold(
              body: Center(child: Text('Invalid chat payload')),
            );
          }
          return ChatThreadScreen(
            chatId: state.pathParameters['chatId']!,
            peerEmail: extra.peerEmail,
            peerDisplayName: extra.peerDisplayName,
            peerPhotoUrl: extra.peerPhotoUrl,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/topics',
        builder: (context, state) => TopicsListScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name',
        builder: (context, state) => SubjectDetailScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/pyq-year/:year',
        builder: (context, state) =>
            PyqYearPacksScreen(year: state.pathParameters['year']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject-test',
        builder: (context, state) {
          final extra = state.extra;
          final isBotBattle = extra is Map && extra['battleMode'] == 'bot';
          return SubjectTestScreen(botBattleMode: isBotBattle);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/topic-test',
        builder: (context, state) => const TopicTestScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle/config',
        builder: (context, state) {
          final invite = state.extra is BattleInviteTarget
              ? state.extra! as BattleInviteTarget
              : null;
          return BattleConfigScreen(invite: invite);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle/join/:sessionId',
        builder: (context, state) =>
            BattleJoinScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle/wait/:sessionId',
        builder: (context, state) {
          final extra = state.extra;
          final data = extra is Map ? extra : const <String, Object?>{};
          return BattleWaitingScreen(
            sessionId: state.pathParameters['sessionId']!,
            playerName: (data['playerName'] as String?) ?? 'You',
            opponentName: (data['opponentName'] as String?) ?? 'Opponent',
            playerPhotoUrl: data['playerPhotoUrl'] as String?,
            opponentPhotoUrl: data['opponentPhotoUrl'] as String?,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle-results/:sessionId',
        builder: (context, state) {
          final payload = state.extra is BattleResultPayload
              ? state.extra as BattleResultPayload
              : null;
          if (payload == null) {
            return ResultsScreen(sessionId: state.pathParameters['sessionId']!);
          }
          return BattleResultScreen(payload: payload);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/test/:sessionId',
        name: 'test_session',
        builder: (context, state) =>
            TestEngineScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle/:sessionId',
        builder: (context, state) =>
            BattleTestScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/results/:sessionId',
        name: 'session_results',
        builder: (context, state) =>
            ResultsScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/danger-zone/:sessionId',
        builder: (context, state) => DangerZoneReviewScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/session-confidence-review/:sessionId/:tier',
        builder: (context, state) {
          final o = state.uri.queryParameters['outcome'];
          return ConfidenceTierReviewScreen(
            sessionId: state.pathParameters['sessionId']!,
            tier: state.pathParameters['tier']!,
            outcomeFilter: (o == 'correct' || o == 'wrong') ? o : null,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/history/:sessionId',
        builder: (context, state) => SessionReviewScreen(
          sessionId: state.pathParameters['sessionId']!,
          focusWrong: state.uri.queryParameters['focus'] == 'wrong',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/revision-queue',
        builder: (context, state) => const RevisionQueueScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/revision-queue/session/:sessionId',
        builder: (context, state) =>
            RevisionModeScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas',
        builder: (context, state) => const WeakAreasHubScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas/subtopic/:subTopic',
        builder: (context, state) =>
            SubTopicDetailScreen(subTopic: state.pathParameters['subTopic']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas/traps',
        builder: (context, state) => const TrapPatternsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas/trap/:trapType',
        builder: (context, state) => TrapPatternDetailScreen(
          trapType: state.pathParameters['trapType']!,
        ),
      ),
    ],
  );
}

/// Triggers [GoRouter] redirect re-evaluation when Remote Config toggles Community.
final class _CommunityTabRedirectRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _CommunityTabIcon extends StatelessWidget {
  const _CommunityTabIcon({
    required this.outlined,
    required this.showUnreadDot,
    required this.scheme,
  });

  final bool outlined;
  final bool showUnreadDot;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(outlined ? Icons.groups_outlined : Icons.groups, size: 22),
        if (showUnreadDot)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
    if (!showUnreadDot) return stack;
    return UnreadPulseWrapper(active: true, scheme: scheme, child: stack);
  }
}

class _AppShell extends HookConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authActionsProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          DeferredPushPermissionCoordinator.clearCommunitySignInArmed();
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(authErrorMessage(error))),
          );
        },
      );
    });

    ref.listen(authStateChangesProvider, (previous, next) {
      if (previous == null) return;
      final wasSignedOut = previous.asData?.value == null;
      final nowSignedIn = next.asData?.value != null;
      if (!wasSignedOut || !nowSignedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final showCommunityTab =
            FeatureFlags.communityTab &&
            ref
                .read(communityTabRemoteEnabledProvider)
                .maybeWhen(data: (v) => v, orElse: () => true);
        unawaited(
          DeferredPushPermissionCoordinator.onSignedInAfterCommunityPromptArmed(
            context,
            ref,
            onSignedInFromCommunityTab: showCommunityTab
                ? () {
                    if (!context.mounted) return;
                    final branches = navigationShell.route.branches;
                    if (branches.isEmpty) return;
                    final communityIndex = branches.length - 1;
                    navigationShell.goBranch(
                      communityIndex,
                      initialLocation: false,
                    );
                    ref.invalidate(communityChallengersProvider);
                    ref.invalidate(openChallengesListProvider);
                    unawaited(
                      ref
                          .read(communityRecentUsersProvider.notifier)
                          .refresh(),
                    );
                  }
                : null,
          ),
        );
      });
    });

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final authState = ref.watch(authStateChangesProvider);
    final authActions = ref.watch(authActionsProvider);
    final isAuthBusy = authActions.isLoading;
    final shellHasCommunity = FeatureFlags.communityTab;
    final remoteCommunity = ref.watch(communityTabRemoteEnabledProvider);
    final showCommunityTab =
        shellHasCommunity &&
        remoteCommunity.maybeWhen(data: (v) => v, orElse: () => true);
    final chatUnreadDot = showCommunityTab
        ? ref.watch(chatInboxHasUnreadProvider)
        : false;

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined, size: 22),
        activeIcon: Icon(Icons.home, size: 22),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.access_time_outlined, size: 22),
        activeIcon: Icon(Icons.access_time, size: 22),
        label: 'History',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined, size: 22),
        activeIcon: Icon(Icons.bar_chart, size: 22),
        label: 'Progress',
      ),
      if (showCommunityTab)
        BottomNavigationBarItem(
          icon: _CommunityTabIcon(
            outlined: true,
            showUnreadDot: chatUnreadDot,
            scheme: scheme,
          ),
          activeIcon: _CommunityTabIcon(
            outlined: false,
            showUnreadDot: chatUnreadDot,
            scheme: scheme,
          ),
          label: 'Community',
        ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 0.5, color: borderColor),
          BottomNavigationBar(
            currentIndex: () {
              if (!shellHasCommunity) return navigationShell.currentIndex;
              if (showCommunityTab) return navigationShell.currentIndex;
              final i = navigationShell.currentIndex;
              return i >= 3 ? 0 : i;
            }(),
            onTap: (index) async {
              if (!shellHasCommunity) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
                return;
              }
              if (showCommunityTab) {
                final communityTabIndex = navItems.length - 1;
                if (index == communityTabIndex) {
                  if (authState.asData?.value == null) {
                    await showGoogleLoginBottomSheet(
                      context: context,
                      isLoading: isAuthBusy,
                      onGoogleTap: () {
                        Navigator.of(context).pop();
                        DeferredPushPermissionCoordinator.armCommunitySignInPrompt();
                        ref
                            .read(authActionsProvider.notifier)
                            .signInWithGoogle();
                      },
                    );
                    return;
                  }
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                  ref.invalidate(communityChallengersProvider);
                  ref.invalidate(openChallengesListProvider);
                  unawaited(
                    ref.read(communityRecentUsersProvider.notifier).refresh(),
                  );
                  return;
                }
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
                return;
              }
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: scheme.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
            selectedLabelStyle: AppTextStyles.navLabel(),
            unselectedLabelStyle: AppTextStyles.navLabel(),
            showUnselectedLabels: true,
            items: navItems,
          ),
        ],
      ),
    );
  }
}
