import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/analytics/analytics_app_lifecycle_observer.dart';
import '../core/analytics/analytics.dart';
import '../core/analytics/analytics_events.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/prelims_debug_flags.dart';
import '../core/crashlytics/firebase_crashlytics_bootstrap.dart';
import '../core/providers/app_bootstrap.dart';
import '../core/services/battle_messaging_service.dart';
import '../core/services/share_deep_link_service.dart';
import '../core/services/fcm_token_sync_service.dart';
import '../features/community/services/community_bucket_presence_service.dart';
import '../features/home/providers/auth_providers.dart';
import '../core/providers/prefs_provider.dart';
import '../core/router/app_router.dart'
    show appRouterProvider, rootNavigatorKey;
import '../core/router/question_bank_loading_screen.dart';
import '../core/services/prelims_surfaces_refresh.dart';
import '../core/theme/app_theme.dart';
import '../features/battle/widgets/battle_spectate_overlay.dart';
import '../shared/widgets/first_launch_bilingual_welcome_sheet.dart';

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
    final welcomeScheduled = useRef(false);

    /// First launch only: [PrefsService.bilingualQuestionWelcomeSeen].
    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        final prefs = await ref.read(prefsServiceProvider.future);
        if (cancelled || prefs.bilingualQuestionWelcomeSeen) return;
        if (welcomeScheduled.value) return;
        welcomeScheduled.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(() async {
            final navCtx = rootNavigatorKey.currentContext;
            if (navCtx == null || !navCtx.mounted) {
              welcomeScheduled.value = false;
              return;
            }
            final svc = await ref.read(prefsServiceProvider.future);
            if (cancelled ||
                !navCtx.mounted ||
                svc.bilingualQuestionWelcomeSeen) {
              return;
            }
            await showFirstLaunchBilingualWelcomeSheet(navCtx);
            if (cancelled || !navCtx.mounted) return;
            (await ref.read(
              prefsServiceProvider.future,
            )).bilingualQuestionWelcomeSeen = true;
          }());
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
      data: (service) =>
          service.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );
    return MaterialApp.router(
      title: AppConstants.appDisplayName,
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
