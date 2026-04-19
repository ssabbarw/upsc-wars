import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Sends Riverpod provider failures to Crashlytics as non-fatal events (the UI
/// often surfaces [AsyncValue] errors without crashing).
final class CrashlyticsProviderObserver extends ProviderObserver {
  const CrashlyticsProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _report(
      error,
      stackTrace,
      'riverpod_provider:${context.provider}',
    );
  }

  void _report(Object error, StackTrace stackTrace, String reason) {
    if (kIsWeb) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      ),
    );
  }
}
