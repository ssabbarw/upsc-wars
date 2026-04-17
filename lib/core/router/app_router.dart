import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/feature_flags.dart';
import '../../features/bookmarks/screens/bookmarks_screen.dart';
import '../../features/battle/screens/battle_test_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/history/screens/session_review_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/community_connect_screen.dart';
import '../../features/community/providers/community_providers.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/profile_screen.dart';
import '../../features/home/screens/progress_screen.dart';
import '../../features/home/providers/auth_providers.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/revision_queue/screens/revision_queue_screen.dart';
import '../../features/revision_queue/screens/revision_mode_screen.dart';
import '../../features/subject_test/screens/subject_test_screen.dart';
import '../../features/test_engine/screens/test_engine_screen.dart';
import '../../features/topic_test/screens/topic_test_screen.dart';
import '../../features/weak_areas/screens/weak_areas_hub_screen.dart';
import '../../features/weak_areas/screens/concept_detail_screen.dart'
    show SubTopicDetailScreen;
import '../../features/weak_areas/screens/trap_patterns_screen.dart';
import '../../features/weak_areas/screens/trap_pattern_detail_screen.dart';
import '../../shared/widgets/google_login_bottom_sheet.dart';
import '../providers/app_bootstrap.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  ref.watch(appBootstrapProvider).requireValue;
  final shellBranches = <StatefulShellBranch>[
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
      ],
    ),
    if (FeatureFlags.communityTab)
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
          ),
        ],
      ),
  ];
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
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
        path: '/community/connect',
        builder: (context, state) {
          return CommunityConnectScreen(selectedUser: state.extra);
        },
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
        path: '/test/:sessionId',
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
        builder: (context, state) =>
            ResultsScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/history/:sessionId',
        builder: (context, state) =>
            SessionReviewScreen(sessionId: state.pathParameters['sessionId']!),
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

class _AppShell extends HookConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authActionsProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(authErrorMessage(error))),
          );
        },
      );
    });

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final authState = ref.watch(authStateChangesProvider);
    final authActions = ref.watch(authActionsProvider);
    final isAuthBusy = authActions.isLoading;
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
      if (FeatureFlags.communityTab)
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined, size: 22),
          activeIcon: Icon(Icons.groups, size: 22),
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
            currentIndex: navigationShell.currentIndex,
            onTap: (index) async {
              final communityTabIndex = FeatureFlags.communityTab
                  ? navItems.length - 1
                  : -1;

              if (FeatureFlags.communityTab && index == communityTabIndex) {
                if (authState.asData?.value == null) {
                  await showGoogleLoginBottomSheet(
                    context: context,
                    isLoading: isAuthBusy,
                    onGoogleTap: () {
                      Navigator.of(context).pop();
                      ref.read(authActionsProvider.notifier).signInWithGoogle();
                    },
                  );
                  return;
                }
                // Always reload recents whenever Community tab is tapped.
                await ref.read(communityRecentUsersProvider.notifier).refresh();
                ref.invalidate(communityChallengersProvider);
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
