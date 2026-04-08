import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/bookmarks/screens/bookmarks_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/history/screens/session_review_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/profile_screen.dart';
import '../../features/home/screens/progress_screen.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/revision_queue/screens/revision_queue_screen.dart';
import '../../features/revision_queue/screens/revision_mode_screen.dart';
import '../../features/subject_test/screens/subject_test_screen.dart';
import '../../features/test_engine/screens/test_engine_screen.dart';
import '../../features/topic_test/screens/topic_test_screen.dart';
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
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject-test',
        builder: (context, state) => const SubjectTestScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/topic-test',
        builder: (context, state) => const TopicTestScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/test/:sessionId',
        builder:
            (context, state) =>
                TestEngineScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/results/:sessionId',
        builder:
            (context, state) =>
                ResultsScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/history/:sessionId',
        builder:
            (context, state) => SessionReviewScreen(
              sessionId: state.pathParameters['sessionId']!,
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
        builder:
            (context, state) => RevisionModeScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
    ],
  );
}

class _AppShell extends HookConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 0.5, color: borderColor),
          BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap:
                (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: scheme.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
            selectedLabelStyle: AppTextStyles.navLabel(),
            unselectedLabelStyle: AppTextStyles.navLabel(),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home, size: 22),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time_outlined, size: 22),
                activeIcon: Icon(Icons.access_time, size: 22),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined, size: 22),
                activeIcon: Icon(Icons.bar_chart, size: 22),
                label: 'Progress',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 22),
                activeIcon: Icon(Icons.person, size: 22),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
