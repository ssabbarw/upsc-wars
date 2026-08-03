import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/auth/auth_session.dart';
import '../core/debug/upsc_wars_trace.dart';
import '../core/admin_dashboard/admin_dashboard_service.dart';
import '../core/analytics/analytics_app_lifecycle_observer.dart';
import '../core/analytics/activation_milestones.dart';
import '../core/analytics/analytics.dart';
import '../core/analytics/analytics_events.dart';
import '../core/analytics/analytics_global_dispatch.dart';
import '../core/analytics/push_notification_status_snapshot.dart';
import '../core/providers/analytics_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/prelims_debug_flags.dart';
import '../core/crashlytics/firebase_crashlytics_bootstrap.dart';
import '../core/providers/app_bootstrap.dart';
import '../core/providers/kill_switch_provider.dart';
import '../core/services/battle_messaging_service.dart';
import '../core/services/daily_practice_reminder_service.dart';
import '../core/services/no_test_reminder_service.dart';
import '../core/services/share_deep_link_service.dart';
import '../core/services/fcm_token_sync_service.dart';
import '../core/services/question_stats_sync_service.dart';
import '../features/question_editor/providers/question_editor_providers.dart';
import '../features/community/services/community_bucket_presence_service.dart';
import '../features/home/providers/auth_providers.dart';
import '../core/providers/prefs_provider.dart';
import '../core/providers/user_database_provider.dart';
import '../core/router/app_router.dart'
    show appRouterProvider;
import '../core/router/question_bank_loading_screen.dart';
import '../core/services/prelims_surfaces_refresh.dart';
import '../core/theme/app_theme.dart';
import '../features/battle/widgets/battle_chat_fab.dart';
import '../features/battle/widgets/battle_spectate_overlay.dart';
class UpscWarsApp extends HookConsumerWidget {
  const UpscWarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(appBootstrapProvider);
    final prefs = ref.watch(prefsServiceProvider);
    final themeMode = prefs.maybeWhen(
      data: (service) =>
          service.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );
    return boot.when(
      data: (_) => const _RootMaterialApp(),
      loading: () => MaterialApp(
        title: AppConstants.appDisplayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const QuestionBankLoadingScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        title: AppConstants.appDisplayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: _BootstrapErrorScreen(error: error, stackTrace: stackTrace),
      ),
    );
  }
}

class _RootMaterialApp extends HookConsumerWidget {
  const _RootMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        final prefs = await ref.read(prefsServiceProvider.future);
        if (cancelled || prefs.patternInterruptOnboardingSeen) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cancelled) return;
          final router = ref.read(appRouterProvider);
          final cfg = router.routerDelegate.currentConfiguration;
          final matchedLocation = cfg.isEmpty
              ? router.routeInformationProvider.value.uri.path
              : router.state.matchedLocation;
          if (matchedLocation != '/') return;
          router.go('/onboarding');
        });
      }());
      return () {
        cancelled = true;
      };
    }, const []);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(appRouterProvider);
        unawaited(BattleMessagingService.initialize(router));
        unawaited(ShareDeepLinkService.initialize(ref, router));
      });
      return () {
        unawaited(ShareDeepLinkService.dispose());
      };
    }, const []);

    useEffect(() {
      void dispatch(AnalyticsEvent e) {
        unawaited(ref.read(analyticsServiceProvider).track(e));
      }

      bindGlobalAnalytics(dispatch);
      unawaited(Analytics.track(ref, const AppOpenedEvent()));
      unawaited(() async {
        final p = await ref.read(prefsServiceProvider.future);
        final wasFirstInstall =
            !p.hasActivationMilestone(ActivationMilestones.firstProcessLaunch);
        NoTestReminderService.recordFirstInstallIfNeeded(p);
        await logActivationMilestoneForServices(
          ref.read(analyticsServiceProvider),
          p,
          id: ActivationMilestones.firstProcessLaunch,
        );
        await ref.read(killSwitchProvider.future);
        if (wasFirstInstall) {
          unawaited(AdminDashboardWriterService().recordNewDownload());
        }
        try {
          final db = ref.read(userDatabaseProvider);
          final completedCount = await db.sessionsDao.countCompletedSessions();
          await NoTestReminderService.sync(
            prefs: p,
            completedSessionCount: completedCount,
          );
          final now = DateTime.now();
          final dayStart = DateTime(now.year, now.month, now.day);
          final completedDrillToday =
              await db.sessionsDao.hasCompletedDailyDrillBetween(
            startInclusive: dayStart,
            endExclusive: dayStart.add(const Duration(days: 1)),
          );
          await DailyPracticeReminderService.sync(
            prefs: p,
            activationComplete: p.homeActivationComplete,
            completedToday: completedDrillToday,
          );
        } catch (e, st) {
          upscWarsTrace('no_test_reminder_sync error', error: e, stackTrace: st);
        }
      }());
      unawaited(trackPushNotificationStatusSnapshot(ref));
      unawaited(() async {
        try {
          final db = ref.read(userDatabaseProvider);
          await QuestionStatsSyncService(userDb: db).syncAllPending();
        } catch (e, st) {
          upscWarsTrace('question_stats_flush error', error: e, stackTrace: st);
        }
      }());
      unawaited(() async {
        try {
          await ref.read(killSwitchProvider.future);
          final sync = await ref.read(questionCorrectionsSyncServiceProvider.future);
          final applied = await sync.syncIfNeeded();
          if (applied > 0) {
            upscWarsTrace('question_corrections_sync applied=$applied');
          }
        } catch (e, st) {
          upscWarsTrace(
            'question_corrections_sync error',
            error: e,
            stackTrace: st,
          );
        }
      }());
      final analyticsLifecycle = AnalyticsAppLifecycleObserver(ref);
      WidgetsBinding.instance.addObserver(analyticsLifecycle);
      return () {
        bindGlobalAnalytics(null);
        WidgetsBinding.instance.removeObserver(analyticsLifecycle);
      };
    }, const []);

    useEffect(() {
      final observer = _PrelimsNotificationResumeObserver(
        onResumed: () {
          unawaited(PrelimsSurfacesRefresh.refreshAllSurfaces());
        },
      );
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);

    useEffect(() {
      if (!PrelimsDebugFlags.surfacesEveryMinute) return null;
      final timer = Timer.periodic(const Duration(minutes: 1), (_) {
        unawaited(PrelimsSurfacesRefresh.refreshAllSurfaces());
      });
      return timer.cancel;
    }, const []);

    useEffect(() {
      final timer = Timer.periodic(
        QuestionStatsSyncService.periodicScanInterval,
        (_) {
          unawaited(() async {
            try {
              final db = ref.read(userDatabaseProvider);
              await QuestionStatsSyncService(userDb: db).syncAllPending();
            } catch (e, st) {
              upscWarsTrace(
                'question_stats_periodic_flush error',
                error: e,
                stackTrace: st,
              );
            }
          }());
        },
      );
      return timer.cancel;
    }, const []);

    ref.listen<AsyncValue<User?>>(
      authStateChangesProvider,
      (prev, next) {
        if (!next.hasValue) return;
        final u = next.requireValue;
        if (!AuthSession.isAccountSignedIn(u)) return;
        unawaited(FcmTokenSyncService.syncForCurrentUser());
        unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
        User? prevUser;
        if (prev is AsyncData<User?>) prevUser = prev.value;
        if (!AuthSession.isAccountSignedIn(prevUser)) {
          unawaited(
            logActivationMilestoneOnce(
              ref,
              ActivationMilestones.firstAccountSignIn,
            ),
          );
        }
      },
    );

    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(prefsServiceProvider);
    final themeMode = prefs.maybeWhen(
      data: (service) =>
          service.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );
    return MaterialApp.router(
      title: AppConstants.appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) {
          upscWarsTrace(
            'MaterialApp.router builder: child is null '
            '(blank frame if this repeats)',
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            const BattleSpectateFabHost(),
            const BattleChatFabHost(),
          ],
        );
      },
    );
  }
}

class _BootstrapErrorScreen extends StatefulWidget {
  const _BootstrapErrorScreen({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  State<_BootstrapErrorScreen> createState() => _BootstrapErrorScreenState();
}

class _BootstrapErrorScreenState extends State<_BootstrapErrorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(reportBootstrapFailure(widget.error, widget.stackTrace));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          widget.error.toString(),
          style: AppTheme.light().textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _PrelimsNotificationResumeObserver extends WidgetsBindingObserver {
  _PrelimsNotificationResumeObserver({required this.onResumed});

  final void Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
