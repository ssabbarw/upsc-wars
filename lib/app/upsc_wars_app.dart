import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/auth/auth_session.dart';
import '../core/debug/upsc_wars_trace.dart';
import '../core/admin_dashboard/admin_dashboard_service.dart';
import '../core/analytics/analytics_app_lifecycle_observer.dart';
import '../core/analytics/activation_milestones.dart';
import '../core/analytics/analytics.dart';
import '../core/analytics/analytics_events.dart';
import '../core/analytics/analytics_global_dispatch.dart';
import '../core/analytics/firebase_analytics_sink.dart';
import '../core/analytics/posthog_analytics_sink.dart';
import '../core/analytics/push_notification_status_snapshot.dart';
import '../core/analytics/session_entry_source.dart';
import '../core/providers/analytics_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/prelims_debug_flags.dart';
import '../core/crashlytics/firebase_crashlytics_bootstrap.dart';
import '../core/providers/app_bootstrap.dart';
import '../core/providers/kill_switch_provider.dart';
import '../core/services/battle_messaging_service.dart';
import '../core/services/local_daily_reminders_sync.dart';
import '../core/services/no_test_reminder_service.dart';
import '../core/services/share_deep_link_service.dart';
import '../core/services/fcm_token_sync_service.dart';
import '../core/services/question_stats_sync_service.dart';
import '../features/question_editor/providers/question_editor_providers.dart';
import '../features/community/services/community_bucket_presence_service.dart';
import '../features/home/providers/auth_providers.dart';
import '../features/home/providers/data_restore_provider.dart';
import '../core/providers/prefs_provider.dart';
import '../core/providers/app_language_helpers.dart';
import '../core/providers/catalog_providers.dart' show appLanguageProvider;
import '../l10n/l10n.dart';
import '../core/providers/user_database_provider.dart';
import '../core/auth/super_user.dart';
import '../core/router/app_router.dart' show appRouterProvider;
import '../features/fomo_pulse/data/fomo_pulse_incoming_share.dart';
import '../core/router/question_bank_loading_screen.dart';
import '../core/services/prelims_surfaces_refresh.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/reading_font_scale.dart';
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
      void dispatch(AnalyticsEvent e) {
        unawaited(ref.read(analyticsServiceProvider).track(e));
      }

      bindGlobalAnalytics(dispatch);
      unawaited(() async {
        final router = ref.read(appRouterProvider);
        // Resolve cold-start push / deep-link attribution before app_opened.
        await BattleMessagingService.initialize(router);
        await ShareDeepLinkService.initialize(ref, router);
        final currentUser = FirebaseAuth.instance.currentUser;
        await FirebaseAnalyticsSink.syncCollectionForUser(currentUser);
        await PostHogAnalyticsSink.syncForUser(currentUser);
        final entry = SessionEntrySource.consume();
        await Analytics.track(
          ref,
          AppOpenedEvent(entrySource: entry.source, entryDetail: entry.detail),
        );
        unawaited(maybeLogReturnAfterDemo(ref));
        final p = await ref.read(prefsServiceProvider.future);
        final wasFirstInstall = !p.hasActivationMilestone(
          ActivationMilestones.firstProcessLaunch,
        );
        NoTestReminderService.recordFirstInstallIfNeeded(p);
        await logActivationMilestoneForServices(
          ref.read(analyticsServiceProvider),
          p,
          id: ActivationMilestones.firstProcessLaunch,
        );
        await ref.read(killSwitchProvider.future);
        unawaited(FcmTokenSyncService.syncForCurrentUser());
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
          await LocalDailyRemindersSync.sync(
            prefs: p,
            db: db,
            dailyCaEnabled: await ref.read(dailyCaRemoteEnabledProvider.future),
          );
        } catch (e, st) {
          upscWarsTrace(
            'no_test_reminder_sync error',
            error: e,
            stackTrace: st,
          );
        }
      }());
      Future<void> syncLocalDailyReminders() async {
        try {
          final p = await ref.read(prefsServiceProvider.future);
          final db = ref.read(userDatabaseProvider);
          await LocalDailyRemindersSync.sync(
            prefs: p,
            db: db,
            dailyCaEnabled: await ref.read(dailyCaRemoteEnabledProvider.future),
          );
        } catch (e, st) {
          upscWarsTrace(
            'local_daily_reminders_sync error',
            error: e,
            stackTrace: st,
          );
        }
      }

      void onNotificationPermissionMayHaveChanged() {
        unawaited(syncLocalDailyReminders());
      }

      BattleMessagingService.addNotificationPermissionChangeListener(
        onNotificationPermissionMayHaveChanged,
      );
      final localRemindersLifecycle = _PrelimsNotificationResumeObserver(
        onResumed: onNotificationPermissionMayHaveChanged,
      );
      WidgetsBinding.instance.addObserver(localRemindersLifecycle);
      unawaited(trackPushNotificationStatusSnapshot(ref));
      unawaited(() async {
        try {
          final db = ref.read(userDatabaseProvider);
          await QuestionStatsSyncService(userDb: db).syncAllPending();
        } catch (e, st) {
          upscWarsTrace('question_stats_flush error', error: e, stackTrace: st);
        }
      }());
      // Already-signed-in launch: the auth listener below only fires on
      // changes, so kick off restore/backup flush explicitly.
      unawaited(
        ref
            .read(dataRestoreProvider.notifier)
            .onUserChanged(FirebaseAuth.instance.currentUser),
      );
      unawaited(() async {
        try {
          await ref.read(killSwitchProvider.future);
          final sync = await ref.read(
            questionCorrectionsSyncServiceProvider.future,
          );
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
        BattleMessagingService.removeNotificationPermissionChangeListener(
          onNotificationPermissionMayHaveChanged,
        );
        WidgetsBinding.instance.removeObserver(localRemindersLifecycle);
        WidgetsBinding.instance.removeObserver(analyticsLifecycle);
        unawaited(ShareDeepLinkService.dispose());
      };
    }, const []);

    useEffect(() {
      final observer = _PrelimsNotificationResumeObserver(
        onResumed: () {
          unawaited(PrelimsSurfacesRefresh.refreshAllSurfaces());
          unawaited(
            ShareDeepLinkService.handleResume(ref, ref.read(appRouterProvider)),
          );
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
              final backup = ref.read(sessionBackupServiceProvider);
              // No-op once the one-time backfill has succeeded; otherwise
              // resumes it after an offline/failed attempt.
              await backup.runBackfillOnce();
              await backup.retryPending();
              // Local hash compare; only writes if a bookmark change failed to upload.
              await ref.read(bookmarkBackupServiceProvider).syncIfChanged();
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

    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (prev, next) {
      final u = next.asData?.value;
      unawaited(FirebaseAnalyticsSink.syncCollectionForUser(u));
      unawaited(PostHogAnalyticsSink.syncForUser(u));
      if (!next.hasValue) return;
      if (!AuthSession.isAccountSignedIn(u)) return;
      // Pull this account's backed-up tests onto a fresh install (shows the
      // "Restoring your data" card on Home), then flush anything pending.
      unawaited(ref.read(dataRestoreProvider.notifier).onUserChanged(u));
      unawaited(FcmTokenSyncService.syncForCurrentUser());
      unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
      User? prevUser;
      if (prev is AsyncData<User?>) prevUser = prev.value;
      if (!AuthSession.isAccountSignedIn(prevUser)) {
        final method = (u != null && u.providerData.isNotEmpty)
            ? u.providerData.first.providerId
            : null;
        unawaited(Analytics.track(ref, AccountSignedInEvent(method: method)));
        unawaited(
          logActivationMilestoneOnce(
            ref,
            ActivationMilestones.firstAccountSignIn,
          ),
        );
      }
      if (SuperUser.isSignedIn(u)) {
        FomoPulseIncomingShareStore.consumePending(
          fallback: ref.read(appRouterProvider),
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(prefsServiceProvider);
    final themeMode = prefs.maybeWhen(
      data: (service) =>
          service.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );
    // One language setting drives both the UI and question content. `.value`
    // keeps the previous language while the provider reloads after a switch,
    // so the UI does not flash back to English.
    final language = normalizeAppLanguage(
      ref.watch(appLanguageProvider).value ?? prefs.value?.language,
    );
    AppL10n.locale = Locale(language);
    // Month / weekday names in `DateFormat(...)` follow the app language.
    Intl.defaultLocale = language;
    return MaterialApp.router(
      title: AppConstants.appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) {
          upscWarsTrace(
            'MaterialApp.router builder: child is null '
            '(blank frame if this repeats)',
          );
        }
        return ReadingFontScaleHost(
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const BattleSpectateFabHost(),
              const BattleChatFabHost(),
            ],
          ),
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
