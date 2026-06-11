import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/upsc_wars_app.dart';
import 'core/debug/upsc_wars_trace.dart';
import 'core/crashlytics/crashlytics_provider_observer.dart';
import 'core/crashlytics/firebase_crashlytics_bootstrap.dart';
import 'core/constants/prelims_debug_flags.dart';
import 'core/services/anonymous_auth_service.dart';
import 'core/services/firebase_in_app_messaging_service.dart';
import 'core/services/battle_messaging_service.dart';
import 'core/services/prelims_surfaces_refresh.dart';
import 'core/services/prelims_workmanager_callback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never fetch fonts over the network at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    upscWarsTrace(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    upscWarsTrace('PlatformDispatcher.onError', error: error, stackTrace: stack);
    return false;
  };

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp();
  await AnonymousAuthService.ensureSignedIn();
  await setupFirebaseCrashlytics();
  await FirebaseInAppMessagingService.initializeAfterFirebase();
  // Capture tap-to-open payload before runApp. On Android, reading
  // getInitialMessage too late can leave data unavailable for routing.
  final openedFromNotification = await FirebaseMessaging.instance
      .getInitialMessage();
  if (openedFromNotification != null) {
    BattleMessagingService.setPendingOpenedNotification(openedFromNotification);
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Workmanager().initialize(prelimsWorkmanagerCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      PrelimsSurfacesRefresh.periodicTaskUniqueName,
      PrelimsSurfacesRefresh.periodicTaskName,
      frequency: PrelimsDebugFlags.surfacesEveryMinute
          ? const Duration(minutes: 1)
          : const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
  unawaited(PrelimsSurfacesRefresh.refreshAllSurfaces());
  runApp(
    const ProviderScope(
      observers: [CrashlyticsProviderObserver()],
      child: UpscWarsApp(),
    ),
  );
}
