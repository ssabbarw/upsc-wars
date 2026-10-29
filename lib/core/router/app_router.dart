import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_session.dart';
import '../analytics/activation_milestones.dart';
import '../analytics/analytics_route_observer.dart';
import '../analytics/screen_dwell_route_observer.dart';
import '../analytics/screen_flow_analytics.dart';
import '../debug/upsc_wars_trace.dart';
import '../config/feature_flags.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../constants/app_constants.dart';
import '../constants/subject_constants.dart';
import '../theme/app_text_styles.dart';
import '../../features/test_series/screens/my_test_series_screen.dart';
import '../../features/test_series/screens/series_subject_screen.dart';
import '../../features/test_series/screens/test_series_home_screen.dart';
import '../../features/bookmarks/screens/bookmarks_screen.dart';
import '../../features/battle/domain/entities/battle_result_payload.dart';
import '../../features/battle/domain/entities/battle_invite_target.dart';
import '../../features/battle/screens/battle_config_screen.dart';
import '../../features/battle/screens/battle_join_screen.dart';
import '../../features/battle/screens/battle_result_screen.dart';
import '../../features/battle/screens/battle_test_screen.dart';
import '../../features/battle/screens/battle_waiting_screen.dart';
import '../../features/history/screens/question_list_review_screen.dart';
import '../../features/history/screens/session_review_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/blocked_users_screen.dart';
import '../../features/community/screens/post_qotd_flow_screen.dart';
import '../../features/community/screens/community_connect_screen.dart';
import '../../features/community/screens/open_challenge_detail_screen.dart';
import '../../features/community/screens/open_challenge_pick_subject_screen.dart';
import '../../features/community/providers/community_providers.dart';
import '../../features/community/providers/open_challenge_providers.dart';
import '../../features/chat/chat_fcm.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_thread_screen.dart';
import '../../features/home/screens/daily_drill_launch_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/domain/today_hero.dart';
import '../../features/onboarding/screens/onboarding_flow_screen.dart';
import '../../features/notifications/screens/long_html_notification_screen.dart';
import '../../features/daily_ca/screens/daily_ca_screen.dart';
import '../../features/daily_ca/screens/daily_ca_review_screen.dart';
import '../../features/daily_ca/screens/daily_ca_review_edit_screen.dart';
import '../../features/daily_ca/screens/daily_ca_results_screen.dart';
import '../../features/daily_ca/screens/daily_ca_leaderboard_screen.dart';
import '../../features/daily_war/providers/daily_war_providers.dart';
import '../../features/daily_war/screens/daily_war_badges_screen.dart';
import '../../features/daily_war/screens/daily_war_history_detail_screen.dart';
import '../../features/daily_war/screens/daily_war_history_revise_screen.dart';
import '../../features/daily_war/screens/daily_war_history_screen.dart';
import '../../features/daily_war/screens/daily_war_leaderboard_screen.dart';
import '../../features/daily_war/screens/daily_war_results_screen.dart';
import '../../features/pyq/screens/pyq_year_packs_screen.dart';
import '../../features/home/screens/complete_profile_screen.dart';
import '../../features/home/screens/profile_screen.dart';
import '../../features/home/screens/settings_screen.dart';
import '../../features/home/screens/about_us_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/practice_tests/screens/practice_confidence_traps_screen.dart';
import '../../features/practice_tests/screens/practice_subject_insights_screen.dart';
import '../../features/practice_tests/screens/practice_test_list_screen.dart';
import '../../features/daily_war/screens/daily_war_admin_screen.dart';
import '../../features/internal/screens/bot_battles_admin_screen.dart';
import '../../features/internal/screens/broadcast_announcement_screen.dart';
import '../../features/internal/screens/test_series_promos_admin_screen.dart';
import '../../features/internal/screens/feature_health_screen.dart';
import '../../features/internal/screens/push_debug_screen.dart';
import '../../features/internal/play_store_demo/play_store_demo_screen.dart';
import '../../features/question_editor/screens/question_editor_form_screen.dart';
import '../../features/question_editor/screens/question_editor_preview_screen.dart';
import '../../features/question_editor/screens/question_editor_search_screen.dart';
import '../../features/question_editor/widgets/question_editor_access.dart';
import '../../features/push_spot_test/screens/spot_test_composer_screen.dart';
import '../../features/home/providers/auth_providers.dart';
import '../../features/results/screens/confidence_tier_review_screen.dart';
import '../../features/results/screens/mistake_review_intro_screen.dart';
import '../../features/results/screens/mistake_review_screen.dart';
import '../../features/push_spot_test/push_spot_test_launch_params.dart';
import '../../features/push_spot_test/screens/push_spot_results_screen.dart';
import '../../features/push_spot_test/screens/push_spot_test_launch_screen.dart';
import '../../features/daily_ca/daily_ca_share_constants.dart';
import '../../features/fomo_pulse/data/fomo_pulse_incoming_share.dart';
import '../../features/fomo_pulse/fomo_pulse_constants.dart';
import '../../features/fomo_pulse/screens/fomo_pulse_article_screen.dart';
import '../../features/fomo_pulse/screens/fomo_pulse_composer_screen.dart';
import '../../features/fomo_pulse/screens/fomo_pulse_detail_screen.dart';
import '../../features/fomo_pulse/screens/fomo_pulse_history_screen.dart';
import '../../features/fomo_pulse/screens/fomo_pulse_mcq_screen.dart';
import '../../features/llm_admin/screens/llm_admin_settings_screen.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/memory_pairs/push/push_memory_pairs_launch_params.dart';
import '../../features/memory_pairs/screens/memory_pairs_screen.dart';
import '../../features/memory_pairs/screens/push_memory_pairs_welcome_screen.dart';
import '../../features/mini_games/hub/games_hub_screen.dart';
import '../../features/mini_games/push/push_revision_game_fcm.dart';
import '../../features/mini_games/timeline_sorter/timeline_sorter_screen.dart';
import '../../features/mini_games/odd_one_out/odd_one_out_screen.dart';
import '../../features/mini_games/fact_or_bluff/fact_or_bluff_screen.dart';
import '../../features/mini_games/connect_the_dots/connect_the_dots_screen.dart';
import '../../features/mini_games/duel/duel_screen.dart';
import '../../features/revision_queue/screens/revision_queue_screen.dart';
import '../../features/revision_queue/screens/revision_mode_screen.dart';
import '../../features/subject_detail/screens/subject_detail_screen.dart';
import '../../features/subject_detail/screens/topics_list_screen.dart';
import '../../features/subject_test/screens/subject_test_screen.dart';
import '../../features/test_engine/screens/demo_test_launch_screen.dart';
import '../../features/test_engine/screens/test_engine_screen.dart';
import '../deep_link/shared_test_launch_screen.dart';
import '../../features/weak_areas/screens/weak_areas_hub_screen.dart';
import '../../features/weak_areas/screens/concept_detail_screen.dart'
    show SubTopicDetailScreen;
import '../../features/weak_areas/screens/trap_patterns_screen.dart';
import '../../features/weak_areas/screens/trap_pattern_detail_screen.dart';
import '../../shared/widgets/google_login_bottom_sheet.dart';
import '../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../shared/widgets/unread_pulse_wrapper.dart';
import '../../shared/widgets/app_toast.dart';
import '../providers/app_bootstrap.dart';
import '../providers/kill_switch_provider.dart';
import '../responsive/app_breakpoints.dart';
import '../../l10n/l10n.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Survives [appRouterProvider] rebuilds (e.g. super-user flag flip) so we do
/// not dump the user on `/` mid-flow.
String? _appRouterRestoreLocation;

String? _hideTestSeries(BuildContext context, GoRouterState state) {
  if (FeatureFlags.testSeries) return null;
  return '/';
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  ref.watch(appBootstrapProvider).requireValue;
  // Watch a stable identity only. Full [authStateChangesProvider] also fires on
  // ID-token refresh (e.g. battle Firestore priming), which would recreate this
  // GoRouter and dump the user back on `/`. Account sign-in is intentionally
  // excluded from [AuthRouterIdentity] for the same reason.
  final authIdentity = ref.watch(authRouterIdentityProvider);
  final authReady = authIdentity.authReady;
  final isSuperUser = authIdentity.isSuperUser;
  final questionEditorAllowed = () =>
      canAccessQuestionEditor(isSuperUser: isSuperUser);
  final shellHasCommunity = FeatureFlags.communityTab;
  final redirectRefresh = _CommunityTabRedirectRefresh();
  ref.onDispose(redirectRefresh.dispose);
  ref.listen(communityTabRemoteEnabledProvider, (_, _) {
    redirectRefresh.notify();
  });
  final restoredLocation = _appRouterRestoreLocation;
  _appRouterRestoreLocation = null;
  final initialLocation = (restoredLocation == null || restoredLocation.isEmpty)
      ? '/'
      : restoredLocation;

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
          builder: (context, state) => HomeScreen(
            heroSlot: TodayHero.slotIdFromQuery(
              state.uri.queryParameters[TodayHero.heroQueryKey],
            ),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/stats',
          name: 'stats',
          builder: (context, state) => const StatsScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/games',
          name: 'games_hub',
          builder: (context, state) => GamesHubScreen(
            asShellTab: true,
            openConfigGame:
                state.uri.queryParameters[PushRevisionGameFcm.queryKeyConfig],
            openConfigNonce:
                state.uri.queryParameters[PushRevisionGameFcm.queryKeyNonce],
          ),
          routes: [
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'timeline-sorter',
              name: 'timeline_sorter',
              builder: (context, state) => TimelineSorterScreen(
                subjectsCsv: state.uri.queryParameters['subjects'] ?? '',
                difficultiesCsv: state.uri.queryParameters['difficulty'] ?? '',
                initialLang: state.uri.queryParameters['lang'] ?? '',
              ),
            ),
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'odd-one-out',
              name: 'odd_one_out',
              builder: (context, state) => OddOneOutScreen(
                subjectsCsv: state.uri.queryParameters['subjects'] ?? '',
                difficultiesCsv: state.uri.queryParameters['difficulty'] ?? '',
                initialLang: state.uri.queryParameters['lang'] ?? '',
              ),
            ),
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'fact-or-bluff',
              name: 'fact_or_bluff',
              builder: (context, state) => FactOrBluffScreen(
                subjectsCsv: state.uri.queryParameters['subjects'] ?? '',
                difficultiesCsv: state.uri.queryParameters['difficulty'] ?? '',
                initialLang: state.uri.queryParameters['lang'] ?? '',
              ),
            ),
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'connect-the-dots',
              name: 'connect_the_dots',
              builder: (context, state) => ConnectTheDotsScreen(
                subjectsCsv: state.uri.queryParameters['subjects'] ?? '',
                difficultiesCsv: state.uri.queryParameters['difficulty'] ?? '',
                initialLang: state.uri.queryParameters['lang'] ?? '',
              ),
            ),
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'duel',
              name: 'duel',
              builder: (context, state) => DuelScreen(
                subjectsCsv: state.uri.queryParameters['subjects'] ?? '',
                difficultiesCsv: state.uri.queryParameters['difficulty'] ?? '',
                initialLang: state.uri.queryParameters['lang'] ?? '',
              ),
            ),
          ],
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
              final highlight = state.uri.queryParameters['highlight'];
              return CommunityScreen(
                initialTabIndex: openChallenge ? 1 : 0,
                highlightOpenChallengeId:
                    openChallenge && highlight != null && highlight.isNotEmpty
                    ? highlight
                    : null,
              );
            },
          ),
        ],
      ),
  ];
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    // The engine remembers the last reported route, so a restart would resume
    // wherever the user was. Cold-start deep links arrive through
    // ShareDeepLinkService, not the platform default location.
    overridePlatformDefaultLocation: true,
    refreshListenable: redirectRefresh,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) {
      upscWarsTrace(
        'GoRouter errorBuilder uri=${state.uri} matched=${state.matchedLocation}',
        error: state.error,
      );
      // Avoid flashing raw exception pages during cold-start deep link handling.
      final p = state.uri.path;
      final isShareLaunch = p.startsWith('/share-launch/');
      if (isShareLaunch) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final raw = (state.error ?? '').toString();
      final looksLikeShareLink = raw.toLowerCase().contains(
        'upscwars.in/share',
      );
      final title = looksLikeShareLink
          ? context.l10n.routerLinkFailedTitle
          : context.l10n.routerErrorTitle;
      final body = looksLikeShareLink
          ? context.l10n.routerLinkFailedBody
          : context.l10n.routerErrorBody;

      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isDark ? AppColors.gray900 : scheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.12,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.wrong.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.link_off_rounded,
                          color: AppColors.wrong,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => GoRouter.of(context).go('/'),
                          child: Text(context.l10n.routerGoHome),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      // Cold-start deep links can arrive as a full https URL "location" on mobile.
      // Normalize `https://upscwars.in/share/<kind>/<uuid>` to our internal route.
      final u = state.uri;
      if (u.pathSegments.any(FomoPulseConstants.isPublicPathSegment) ||
          FomoPulseConstants.isPublicPathSegment(u.host)) {
        upscWarsTrace(
          'GoRouter redirect check uri=$u matched=${state.matchedLocation}',
        );
      }
      if (u.scheme == 'https' || u.scheme == 'http') {
        var host = u.host.toLowerCase();
        var segs = u.pathSegments.where((s) => s.isNotEmpty).toList();

        // Some devices deliver a malformed host/path split like:
        // https://upscwars/in/share/...  -> host=upscwars, segs[0]='in'
        if (host == 'upscwars' && segs.isNotEmpty && segs.first == 'in') {
          host = 'upscwars.in';
          segs = segs.skip(1).toList();
        }

        if (host == 'upscwars.in' && segs.length >= 3 && segs[0] == 'share') {
          final shareId = segs[2].trim();
          final uuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          );
          if (uuid.hasMatch(shareId) &&
              !state.matchedLocation.startsWith('/share-launch/')) {
            return '/share-launch/$shareId';
          }
        }

        if ((host == 'upscwars.in' || host == 'www.upscwars.in') &&
            segs.length >= 2 &&
            FomoPulseConstants.isPublicPathSegment(segs[0])) {
          final pulseId = segs[1].trim();
          final uuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          );
          if (uuid.hasMatch(pulseId) &&
              !state.matchedLocation.startsWith(
                '${FomoPulseConstants.hubLocation}/',
              )) {
            return FomoPulseConstants.detailLocation(
              pulseId,
              source: FomoPulseConstants.entryShare,
            );
          }
        }

        if ((host == 'upscwars.in' || host == 'www.upscwars.in') &&
            segs.length == 2 &&
            DailyCaShareConstants.isPublicPathSegment(segs[0]) &&
            DailyCaShareConstants.isShareableDateSegment(segs[1])) {
          final target = DailyCaShareConstants.dateLocation(
            segs[1],
            source: DailyCaShareConstants.entryShare,
            start: true,
          );
          if (state.matchedLocation != Uri.parse(target).path) {
            return target;
          }
        }
      }

      if (u.scheme == 'upscwars' && u.host.toLowerCase() == 'pulse-article') {
        final articleUrl = articleUrlFromIncomingShareUri(u);
        if (articleUrl != null &&
            !state.matchedLocation.startsWith(
              '/internal/fomo-pulse-composer/article',
            )) {
          return pulseArticleRouteForUrl(articleUrl);
        }
        return null;
      }

      if (u.scheme == 'upscwars' &&
          FomoPulseConstants.isPublicPathSegment(u.host) &&
          u.pathSegments.isNotEmpty) {
        final pulseId = u.pathSegments.first.trim();
        final uuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        if (uuid.hasMatch(pulseId)) {
          return FomoPulseConstants.detailLocation(
            pulseId,
            source: FomoPulseConstants.entryShare,
          );
        }
      }

      if (u.scheme == 'upscwars' &&
          DailyCaShareConstants.isPublicPathSegment(u.host) &&
          u.pathSegments.isNotEmpty &&
          DailyCaShareConstants.isShareableDateSegment(u.pathSegments.first)) {
        return DailyCaShareConstants.dateLocation(
          u.pathSegments.first,
          source: DailyCaShareConstants.entryShare,
          start: true,
        );
      }

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
      ScreenDwellRouteObserver(ref),
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
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/complete-profile',
        name: 'complete_profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/blocked-users',
        name: 'blocked_users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/about-us',
        name: 'about_us',
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/daily-war-admin',
        name: 'daily_war_admin',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const DailyWarAdminScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/bot-battles',
        name: 'bot_battles_admin',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const BotBattlesAdminScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/broadcast',
        name: 'broadcast_announcement',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const BroadcastAnnouncementScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/test-series-promos',
        name: 'test_series_promos_admin',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const TestSeriesPromosAdminScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/feature-health',
        name: 'feature_health',
        builder: (context, state) => const FeatureHealthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/push-debug',
        name: 'push_debug',
        builder: (context, state) {
          if (!kDebugMode && !isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const PushDebugScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/spot-composer',
        name: 'spot_composer',
        builder: (context, state) {
          if (!kDebugMode) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const SpotTestComposerScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/fomo-pulse-composer',
        name: 'fomo_pulse_composer',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const FomoPulseComposerScreen();
        },
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'article',
            name: 'fomo_pulse_article',
            builder: (context, state) {
              if (!authReady) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!isSuperUser) {
                return const Scaffold(
                  body: Center(child: Text('Not available')),
                );
              }
              final args = pulseArticleArgsFromRoute(state);
              if (args != null) {
                return FomoPulseArticleScreen(args: args);
              }
              return const Scaffold(
                body: Center(child: Text('Pick an article first')),
              );
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/llm-settings',
        name: 'llm_admin_settings',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const LlmAdminSettingsScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/play-store-demo',
        name: 'play_store_demo',
        builder: (context, state) {
          if (!kDebugMode) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const PlayStoreDemoScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/question-editor',
        name: 'question_editor',
        builder: (context, state) {
          if (!questionEditorAllowed()) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          return const QuestionEditorSearchScreen();
        },
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'edit',
            name: 'question_editor_edit',
            builder: (context, state) {
              if (!questionEditorAllowed()) {
                return const Scaffold(
                  body: Center(child: Text('Not available')),
                );
              }
              final uuid = state.extra as String? ?? '';
              return QuestionEditorFormScreen(uuid: uuid);
            },
          ),
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'preview',
            name: 'question_editor_preview',
            builder: (context, state) {
              if (!questionEditorAllowed()) {
                return const Scaffold(
                  body: Center(child: Text('Not available')),
                );
              }
              final args = state.extra as QuestionEditorPreviewArgs?;
              if (args == null) {
                return const Scaffold(
                  body: Center(child: Text('Missing preview data')),
                );
              }
              return QuestionEditorPreviewScreen(args: args);
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/internal/daily-ca-review/:date',
        name: 'daily_ca_review',
        builder: (context, state) {
          if (!isSuperUser) {
            return const Scaffold(body: Center(child: Text('Not available')));
          }
          final date = state.pathParameters['date'] ?? '';
          return DailyCaReviewScreen(isoDate: date);
        },
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'edit',
            name: 'daily_ca_review_edit',
            builder: (context, state) {
              if (!isSuperUser) {
                return const Scaffold(
                  body: Center(child: Text('Not available')),
                );
              }
              final raw = state.extra is Map
                  ? Map<String, dynamic>.from(state.extra as Map)
                  : <String, dynamic>{};
              return DailyCaReviewEditScreen(raw: raw);
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/notification/long-html',
        name: 'long_html_notification',
        builder: (context, state) => const LongHtmlNotificationScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/connect',
        name: 'community_connect',
        builder: (context, state) {
          return CommunityConnectScreen(selectedUser: state.extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/qotd/post',
        name: 'qotd_post',
        builder: (context, state) => const PostQotdFlowScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/qotd/explanation',
        name: 'qotd_explanation',
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
        name: 'open_challenge_pick_subject',
        builder: (context, state) => const OpenChallengePickSubjectScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/open-challenges/:challengeId',
        name: 'open_challenge_detail',
        builder: (context, state) => OpenChallengeDetailScreen(
          challengeId: state.pathParameters['challengeId']!,
          backToCommunityOpenTab:
              state.uri.queryParameters['origin'] == 'accept_flow',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/chats',
        name: 'chat_list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/chat/:chatId',
        name: 'chat_thread',
        builder: (context, state) {
          final payload = ChatFcm.payloadFromRoute(
            extra: state.extra,
            queryParameters: state.uri.queryParameters,
          );
          if (payload.peerEmail.isEmpty) {
            upscWarsTrace(
              'chat_thread invalid extra type=${state.extra.runtimeType} '
              'chatIdLen=${state.pathParameters['chatId']?.length ?? 0}',
            );
            return const Scaffold(
              body: Center(child: Text('Invalid chat payload')),
            );
          }
          upscWarsTrace(
            'chat_thread build chatIdLen=${state.pathParameters['chatId']?.length ?? 0} '
            'peerEmailLen=${payload.peerEmail.length}',
          );
          return ChatThreadScreen(
            chatId: state.pathParameters['chatId']!,
            peerEmail: payload.peerEmail,
            peerDisplayName: payload.peerDisplayName,
            peerPhotoUrl: payload.peerPhotoUrl,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/topics',
        name: 'subject_topics',
        builder: (context, state) => TopicsListScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/insights',
        name: 'practice_subject_insights',
        builder: (context, state) => PracticeSubjectInsightsScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/stats/traps',
        name: 'stats_traps',
        builder: (context, state) => const PracticeConfidenceTrapsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/insights/traps',
        name: 'practice_confidence_traps',
        builder: (context, state) => PracticeConfidenceTrapsScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/tests',
        name: 'subject_practice_tests',
        builder: (context, state) => PracticeTestListScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/topic/:topic/tests',
        name: 'topic_practice_tests',
        builder: (context, state) => PracticeTestListScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
          topic: Uri.decodeComponent(state.pathParameters['topic']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/topic/:topic/insights',
        name: 'practice_topic_insights',
        builder: (context, state) => PracticeSubjectInsightsScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
          topic: Uri.decodeComponent(state.pathParameters['topic']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/topic/:topic/insights/traps',
        name: 'practice_topic_confidence_traps',
        builder: (context, state) => PracticeConfidenceTrapsScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
          topic: Uri.decodeComponent(state.pathParameters['topic']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name/history',
        redirect: (context, state) =>
            '/subject/${state.pathParameters['name']}/tests',
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject/:name',
        name: 'subject_detail',
        builder: (context, state) => SubjectDetailScreen(
          subject: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/test-series',
        name: 'test_series',
        redirect: _hideTestSeries,
        builder: (context, state) => const TestSeriesEntryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/test-series/:seriesId',
        name: 'test_series_home',
        redirect: _hideTestSeries,
        builder: (context, state) =>
            TestSeriesHomeScreen(seriesId: state.pathParameters['seriesId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/test-series/:seriesId/subject/:subjectId',
        name: 'test_series_subject',
        redirect: _hideTestSeries,
        builder: (context, state) => SeriesSubjectScreen(
          seriesId: state.pathParameters['seriesId']!,
          subjectId: state.pathParameters['subjectId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/my-test-series',
        name: 'my_test_series',
        redirect: _hideTestSeries,
        builder: (context, state) => const MyTestSeriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-ca',
        name: 'daily_ca',
        builder: (context, state) => DailyCaScreen(
          autoStartPaper: state.uri.queryParameters['start'] == '1',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-ca/results/:sessionId',
        name: 'daily_ca_results',
        builder: (context, state) =>
            DailyCaResultsScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-ca/:dateId/leaderboard',
        name: 'daily_ca_leaderboard',
        builder: (context, state) =>
            DailyCaLeaderboardScreen(dateId: state.pathParameters['dateId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-ca/:dateId',
        name: 'daily_ca_date',
        redirect: (context, state) {
          final dateId = state.pathParameters['dateId']?.trim() ?? '';
          if (!DailyCaShareConstants.isShareableDateSegment(dateId)) {
            return DailyCaShareConstants.hubLocation;
          }
          return null;
        },
        builder: (context, state) {
          final dateId = state.pathParameters['dateId']!;
          final q = state.uri.queryParameters;
          final fromShare = q['src'] == DailyCaShareConstants.entryShare;
          return DailyCaScreen(
            autoStartPaper: fromShare || q['start'] == '1',
            focusDateId: dateId,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-drill/start',
        name: 'daily_drill_start',
        builder: (context, state) => const DailyDrillLaunchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war',
        name: 'daily_war_lobby',
        builder: (context, state) => const DailyWarHistoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war/history',
        name: 'daily_war_history',
        builder: (context, state) => const DailyWarHistoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war/history/badges',
        name: 'daily_war_badges',
        builder: (context, state) => const DailyWarBadgesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war/history/:dateId',
        name: 'daily_war_history_detail',
        builder: (context, state) => DailyWarHistoryDetailScreen(
          dateId: state.pathParameters['dateId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war/history/:dateId/revise',
        name: 'daily_war_history_revise',
        builder: (context, state) {
          final i = int.tryParse(state.uri.queryParameters['i'] ?? '') ?? 0;
          return DailyWarHistoryReviseScreen(
            dateId: state.pathParameters['dateId']!,
            initialIndex: i,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war/history/:dateId/leaderboard',
        name: 'daily_war_leaderboard',
        builder: (context, state) =>
            DailyWarLeaderboardScreen(dateId: state.pathParameters['dateId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-war/results/:sessionId',
        name: 'daily_war_results',
        builder: (context, state) => DailyWarResultsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/pyq-year/:year',
        name: 'pyq_year_packs',
        builder: (context, state) =>
            PyqYearPacksScreen(year: state.pathParameters['year']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subject-test',
        name: 'subject_test',
        builder: (context, state) {
          final extra = state.extra;
          final isBotBattle = extra is Map && extra['battleMode'] == 'bot';
          return SubjectTestScreen(botBattleMode: isBotBattle);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/share-launch/:shareId',
        name: 'share_launch',
        builder: (context, state) {
          return SharedTestLaunchScreen(
            shareId: state.pathParameters['shareId']!,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/topic-test',
        name: 'topic_test',
        redirect: (context, state) =>
            '/subject/${Uri.encodeComponent(SubjectConstants.ordered.first.slug)}/topics',
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle/config',
        name: 'battle_config',
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
        name: 'battle_join',
        builder: (context, state) =>
            BattleJoinScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle/wait/:sessionId',
        name: 'battle_wait',
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
        name: 'battle_results',
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
        path: '/test/pending-demo',
        name: 'demo_test_pending',
        builder: (context, state) => const DemoTestLaunchScreen(),
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
        name: 'battle_test',
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
        path: '/spot-results/:sessionId',
        name: 'push_spot_results',
        builder: (context, state) => PushSpotResultsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/spot-test/launch',
        name: 'push_spot_test_launch',
        builder: (context, state) => PushSpotTestLaunchScreen(
          params: PushSpotTestLaunchParams.fromQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/${FomoPulseConstants.legacyPathSegment}',
        redirect: (context, state) => FomoPulseConstants.hubLocation,
      ),
      GoRoute(
        path: '/${FomoPulseConstants.legacyPathSegment}/:pulseId',
        redirect: (context, state) => FomoPulseConstants.detailLocation(
          state.pathParameters['pulseId']!,
          source: state.uri.queryParameters['src'],
        ),
        routes: [
          GoRoute(
            path: 'mcq',
            redirect: (context, state) => FomoPulseConstants.detailLocation(
              state.pathParameters['pulseId']!,
              source: state.uri.queryParameters['src'],
              mcq: true,
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: FomoPulseConstants.hubLocation,
        name: 'fomo_pulse_history',
        builder: (context, state) => const FomoPulseHistoryScreen(),
      ),
      // Detail is a sibling of the history route so share-link `go` does not
      // rebuild a list-under-detail stack. Notification taps push list then
      // detail on Home instead.
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${FomoPulseConstants.hubLocation}/:pulseId',
        name: 'fomo_pulse_detail',
        builder: (context, state) {
          final id = state.pathParameters['pulseId']!;
          upscWarsTrace('FomoPulseDetailScreen build pulseId=$id');
          return FomoPulseDetailScreen(
            pulseId: id,
            entrySource: FomoPulseConstants.normalizeEntrySource(
              state.uri.queryParameters['src'],
            ),
          );
        },
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'mcq',
            name: 'fomo_pulse_mcq',
            builder: (context, state) => FomoPulseMcqScreen(
              pulseId: state.pathParameters['pulseId']!,
              initialSelectedOption: (state.extra as String?)?.toLowerCase(),
              entrySource: FomoPulseConstants.normalizeEntrySource(
                state.uri.queryParameters['src'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/danger-zone/:sessionId',
        name: 'danger_zone_review',
        redirect: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return '/mistake-review-intro/$sessionId';
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/mistake-review-intro/:sessionId',
        name: 'mistake_review_intro',
        builder: (context, state) => MistakeReviewIntroScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/mistake-review/:sessionId',
        name: 'mistake_review',
        builder: (context, state) =>
            MistakeReviewScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/session-confidence-review/:sessionId/:tier',
        name: 'session_confidence_review',
        builder: (context, state) {
          final o = state.uri.queryParameters['outcome'];
          return ConfidenceTierReviewScreen(
            sessionId: state.pathParameters['sessionId']!,
            tier: state.pathParameters['tier']!,
            outcomeFilter: (o == 'correct' || o == 'wrong') ? o : null,
          );
        },
      ),
      GoRoute(path: '/history', redirect: (context, state) => '/stats'),
      GoRoute(path: '/progress', redirect: (context, state) => '/stats'),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/history/:sessionId',
        name: 'session_history_review',
        builder: (context, state) => SessionReviewScreen(
          sessionId: state.pathParameters['sessionId']!,
          focusWrong: state.uri.queryParameters['focus'] == 'wrong',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/question-review',
        name: 'question_list_review',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! QuestionListReviewArgs) {
            return const Scaffold(
              body: Center(child: Text('Invalid question review navigation')),
            );
          }
          return QuestionListReviewScreen(args: extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/memory-pairs/welcome',
        name: 'memory_pairs_push_welcome',
        builder: (context, state) => PushMemoryPairsWelcomeScreen(
          params: PushMemoryPairsLaunchParams.fromQuery(
            state.uri.queryParameters,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/memory-pairs',
        name: 'memory_pairs',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return MemoryPairsScreen(
            initialSetId: q['set'] ?? q['id'],
            autoplay: q['autoplay'] == '1' || q['autoplay'] == 'true',
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/revision-queue',
        name: 'revision_queue',
        builder: (context, state) => const RevisionQueueScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/revision-queue/session/:sessionId',
        name: 'revision_queue_session',
        builder: (context, state) =>
            RevisionModeScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas',
        name: 'weak_areas_hub',
        builder: (context, state) => const WeakAreasHubScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas/subtopic/:subTopic',
        name: 'weak_areas_subtopic',
        builder: (context, state) =>
            SubTopicDetailScreen(subTopic: state.pathParameters['subTopic']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas/traps',
        name: 'weak_areas_traps',
        builder: (context, state) => const TrapPatternsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/weak-areas/trap/:trapType',
        name: 'weak_area_trap_detail',
        builder: (context, state) => TrapPatternDetailScreen(
          trapType: state.pathParameters['trapType']!,
        ),
      ),
    ],
  );
  ref.onDispose(() {
    try {
      final loc = router.state.uri.toString();
      if (loc.isNotEmpty) _appRouterRestoreLocation = loc;
    } on Object {
      // Router may already be torn down.
    }
  });
  return router;
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
    this.size = 22,
  });

  final bool outlined;
  final bool showUnreadDot;
  final ColorScheme scheme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(outlined ? Icons.groups_outlined : Icons.groups, size: size),
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
    final didPromptCompleteProfile = useRef(false);
    ref.listen(authActionsProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          AppToast.dismiss();
          AppToast.showText(context, authErrorMessage(error));
        },
      );
    });

    ref.listen(authStateChangesProvider, (previous, next) {
      final user = next.asData?.value;
      if (!AuthSession.isAccountSignedIn(user)) {
        didPromptCompleteProfile.value = false;
        return;
      }
      final signedInUser = user!;

      final isAppleUser = signedInUser.providerData.any(
        (p) => p.providerId == 'apple.com',
      );
      final missingName = (signedInUser.displayName ?? '').trim().isEmpty;
      // Apple users can opt out of sharing name. In that case we must ask for it.
      // Profile photo is always optional, so we should not gate on it.
      // This flow must not appear for Google sign-in.
      final needsCompleteProfile = isAppleUser && missingName;

      if (!needsCompleteProfile) {
        didPromptCompleteProfile.value = false;
        return;
      }

      if (!didPromptCompleteProfile.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          didPromptCompleteProfile.value = true;
          final router = GoRouter.of(context);
          final cfg = router.routerDelegate.currentConfiguration;
          final matchedLocation = cfg.isEmpty
              ? router.routeInformationProvider.value.uri.path
              : router.state.matchedLocation;
          if (matchedLocation == '/complete-profile') return;
          router.push('/complete-profile');
        });
      }

      if (previous == null) return;
      final wasSignedOut = !AuthSession.isAccountSignedIn(
        previous.asData?.value,
      );
      final nowSignedIn = AuthSession.isAccountSignedIn(next.asData?.value);
      if (!wasSignedOut || !nowSignedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        // Tonight's attempt is keyed by uid — re-read it for the new account.
        unawaited(ref.read(dailyWarTodaySubmissionProvider.notifier).refresh());
        final showCommunityTab =
            FeatureFlags.communityTab &&
            ref
                .read(communityTabRemoteEnabledProvider)
                .maybeWhen(data: (v) => v, orElse: () => true);
        if (!showCommunityTab) return;
        // Prefetch community data after sign-in, but keep the user on Home.
        ref.invalidate(communityChallengersProvider);
        ref.invalidate(openChallengesListProvider);
        unawaited(ref.read(communityRecentUsersProvider.notifier).refresh());
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

    final tabDwellIndex = useRef(navigationShell.currentIndex);
    final tabDwellAt = useRef(DateTime.now());
    void onWillSwitchMainTab(int toIndex) {
      final from = tabDwellIndex.value;
      if (from != toIndex) {
        final d = DateTime.now().difference(tabDwellAt.value).inMilliseconds;
        if (d >= 0) {
          unawaited(
            ScreenFlow.logShellTabDwellEnded(
              ref,
              fromIndex: from,
              durationMs: d,
              hasCommunity: showCommunityTab,
            ),
          );
        }
      }
      tabDwellIndex.value = toIndex;
      tabDwellAt.value = DateTime.now();
      final names = ScreenFlow.shellTabNames(hasCommunity: showCommunityTab);
      if (toIndex >= 0 && toIndex < names.length && names[toIndex] != 'home') {
        unawaited(maybeLogPostDemoExplore(ref, surface: names[toIndex]));
      }
    }

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined, size: 22),
        activeIcon: Icon(Icons.home, size: 22),
        label: 'Practice',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.insights_outlined, size: 22),
        activeIcon: Icon(Icons.insights, size: 22),
        label: 'Stats',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.sports_esports_outlined, size: 22),
        activeIcon: Icon(Icons.sports_esports, size: 22),
        label: 'Games',
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

    final currentNavIndex = () {
      if (!shellHasCommunity) return navigationShell.currentIndex;
      if (showCommunityTab) return navigationShell.currentIndex;
      final i = navigationShell.currentIndex;
      return i >= 3 ? 0 : i;
    }();

    Future<void> handleTab(int index) async {
      if (!shellHasCommunity) {
        onWillSwitchMainTab(index);
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
        return;
      }
      if (showCommunityTab) {
        final communityTabIndex = navItems.length - 1;
        if (index == communityTabIndex) {
          if (!AuthSession.isAccountSignedIn(authState.asData?.value)) {
            await showGoogleLoginBottomSheet(
              context: context,
              isLoading: isAuthBusy,
              onAppleTap: () {
                Navigator.of(context).pop();
                ref.read(authActionsProvider.notifier).signInWithApple();
              },
              onGoogleTap: () {
                Navigator.of(context).pop();
                ref.read(authActionsProvider.notifier).signInWithGoogle();
              },
            );
            return;
          }
          onWillSwitchMainTab(index);
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
          ref.invalidate(communityChallengersProvider);
          ref.invalidate(openChallengesListProvider);
          unawaited(ref.read(communityRecentUsersProvider.notifier).refresh());
          return;
        }
        onWillSwitchMainTab(index);
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
        return;
      }
      onWillSwitchMainTab(index);
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    // Back for the whole shell is owned here, above the [IndexedStack].
    //
    // [RootBackButtonDispatcher] only invokes the *last* registered callback.
    // This widget rebuilds more often than a tab, so a listener inside a branch
    // never wins. Returning false when we are not on Home used to fall through
    // to the system default — which is to exit the app. Ask the visible tab
    // first (inner sub-tab), then switch to Home, and only then offer exit.
    //
    // [BackButtonListener] re-registers and calls [ChildBackButtonDispatcher.takePriority]
    // whenever [onBackButtonPressed] identity changes. A new closure every build
    // races the root dispatcher (assert: hasCallbacks) during auth/router churn.
    // Keep one stable listener and forward into the latest handler via a ref.
    final shellBackHandler = useRef<Future<bool> Function()>(() async => false);
    shellBackHandler.value = () async {
      // A pushed screen, sheet or dialog on the root navigator owns back first.
      final rootNav = Navigator.maybeOf(context, rootNavigator: true);
      if (rootNav != null && rootNav.canPop()) return false;
      if (ShellInnerBackRegistry.handle()) return true;
      if (navigationShell.currentIndex != 0) {
        navigationShell.goBranch(0, initialLocation: false);
        return true;
      }
      final killBlocked = ref
          .read(killSwitchProvider)
          .maybeWhen(data: (s) => s.isActive, orElse: () => false);
      // The update wall owns the screen; swallow back rather than offer exit.
      if (killBlocked) return true;
      final exit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            context.l10n.routerExitDialogTitle,
            style: AppTextStyles.h3(),
          ),
          content: Text(
            context.l10n.routerExitDialogBody(AppConstants.appDisplayName),
            style: AppTextStyles.bodyMd(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.commonExit),
            ),
          ],
        ),
      );
      if (exit == true) await SystemNavigator.pop();
      return true;
    };
    final onShellBack = useMemoized(
      () =>
          () => shellBackHandler.value(),
      const [],
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= AppBreakpoints.tablet;
    final isLargeTablet = screenWidth >= AppBreakpoints.largeTablet;

    if (isTablet) {
      final railIconSize = isLargeTablet ? 30.0 : 26.0;
      final railDestinations = <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined, size: railIconSize),
          selectedIcon: Icon(Icons.home, size: railIconSize),
          label: const Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined, size: railIconSize),
          selectedIcon: Icon(Icons.bar_chart, size: railIconSize),
          label: const Text('Progress'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sports_esports_outlined, size: railIconSize),
          selectedIcon: Icon(Icons.sports_esports, size: railIconSize),
          label: const Text('Games'),
        ),
        if (showCommunityTab)
          NavigationRailDestination(
            icon: _CommunityTabIcon(
              outlined: true,
              showUnreadDot: chatUnreadDot,
              scheme: scheme,
              size: railIconSize,
            ),
            selectedIcon: _CommunityTabIcon(
              outlined: false,
              showUnreadDot: chatUnreadDot,
              scheme: scheme,
              size: railIconSize,
            ),
            label: const Text('Community'),
          ),
      ];

      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: scheme.surface,
              selectedIndex: currentNavIndex,
              onDestinationSelected: handleTab,
              extended: isLargeTablet,
              selectedIconTheme: IconThemeData(color: AppColors.primary),
              unselectedIconTheme: IconThemeData(
                color: scheme.onSurfaceVariant,
              ),
              selectedLabelTextStyle: AppTextStyles.navLabel().copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: AppTextStyles.navLabel().copyWith(
                color: scheme.onSurfaceVariant,
              ),
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              destinations: railDestinations,
            ),
            VerticalDivider(width: 1, thickness: 0.5, color: borderColor),
            Expanded(child: navigationShell),
          ],
        ),
      ).wrappedWithShellBackListener(onShellBack);
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 0.5, color: borderColor),
            BottomNavigationBar(
              currentIndex: currentNavIndex,
              onTap: handleTab,
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
      ),
    ).wrappedWithShellBackListener(onShellBack);
  }
}

extension on Widget {
  /// Registers [onBack] for the whole shell. See `_AppShell.onShellBack`.
  Widget wrappedWithShellBackListener(Future<bool> Function() onBack) {
    return BackButtonListener(
      onBackButtonPressed: onBack,
      child: PopScope(
        // If the listener is skipped (some OEMs), do not finish the activity.
        canPop: false,
        child: this,
      ),
    );
  }
}
