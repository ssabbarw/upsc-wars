import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/analytics/analytics_app_lifecycle_observer.dart';
import '../core/analytics/analytics.dart';
import '../core/analytics/analytics_events.dart';
import '../core/constants/prelims_debug_flags.dart';
import '../core/providers/app_bootstrap.dart';
import '../core/services/battle_messaging_service.dart';
import '../core/services/fcm_token_sync_service.dart';
import '../features/community/services/community_bucket_presence_service.dart';
import '../features/home/providers/auth_providers.dart';
import '../core/providers/prefs_provider.dart';
import '../core/router/app_router.dart';
import '../core/router/question_bank_loading_screen.dart';
import '../core/services/prelims_surfaces_refresh.dart';
import '../core/theme/app_theme.dart';
import '../features/battle/widgets/battle_spectate_overlay.dart';

class UpscWarsApp extends HookConsumerWidget {
  const UpscWarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(appBootstrapProvider);
    final prefs = ref.watch(prefsServiceProvider);
    final themeMode = prefs.maybeWhen(
      data:
          (service) =>
              service.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );
    return boot.when(
      data: (_) => const _RootMaterialApp(),
      loading: () => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const QuestionBankLoadingScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: Text(
              error.toString(),
              style: AppTheme.light().textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _RootMaterialApp extends HookConsumerWidget {
  const _RootMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(appRouterProvider);
        unawaited(BattleMessagingService.initialize(router));
      });
      return null;
    }, const []);

    useEffect(() {
      unawaited(Analytics.track(ref, const AppOpenedEvent()));
      final analyticsLifecycle = AnalyticsAppLifecycleObserver(ref);
      WidgetsBinding.instance.addObserver(analyticsLifecycle);
      return () => WidgetsBinding.instance.removeObserver(analyticsLifecycle);
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

    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((user) {
        if (user?.email != null) {
          unawaited(FcmTokenSyncService.syncForCurrentUser());
          unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
        }
      });
    });

    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(prefsServiceProvider);
    final themeMode = prefs.maybeWhen(
      data:
          (service) =>
              service.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );
    return MaterialApp.router(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            const BattleSpectateFabHost(),
          ],
        );
      },
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
