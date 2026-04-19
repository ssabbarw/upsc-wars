import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Installs global error handlers and enables collection (mobile/desktop only).
Future<void> setupFirebaseCrashlytics() async {
  if (kIsWeb) {
    FlutterError.onError = FlutterError.dumpErrorToConsole;
    return;
  }

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final previousErrorWidgetBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
    return previousErrorWidgetBuilder(details);
  };
}

/// Non-fatal: startup/bootstrap failed after Firebase is ready.
Future<void> reportBootstrapFailure(Object error, StackTrace stack) async {
  if (kIsWeb) return;
  await FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: 'app_bootstrap',
    fatal: false,
  );
}
