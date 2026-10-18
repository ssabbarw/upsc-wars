import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_audience.dart';
import 'posthog_config.dart';

/// Initializes the PostHog Flutter SDK (manual mode; see Android/iOS AUTO_INIT).
///
/// No-ops when [PostHogAppConfig.apiKey] is missing so local builds without a
/// key still run. Session replay and surveys stay off to protect the free tier.
abstract final class PostHogBootstrap {
  PostHogBootstrap._();

  static bool _started = false;

  static bool get isStarted => _started;

  static Future<void> setup() async {
    if (_started) return;
    if (!PostHogAppConfig.isConfigured) {
      developer.log(
        'PostHog skipped: POSTHOG_API_KEY not set',
        name: 'PostHogBootstrap',
      );
      return;
    }

    try {
      final config = PostHogConfig(PostHogAppConfig.apiKey);
      config.host = PostHogAppConfig.host;
      config.debug = kDebugMode;
      // Curated product events only — avoid duplicating app_opened / session noise.
      config.captureApplicationLifecycleEvents = false;
      config.sessionReplay = false;
      config.surveys = false;
      config.preloadFeatureFlags = false;
      config.sendFeatureFlagEvent = false;
      // Person profiles only after identify(uid) — cheaper than always-identified.
      config.personProfiles = PostHogPersonProfiles.identifiedOnly;
      // Mirror AnalyticsAudience: debug builds never send.
      config.optOut = AnalyticsAudience.isCurrentUserExcluded();

      await Posthog().setup(config);
      _started = true;
    } catch (e, st) {
      developer.log(
        'PostHog setup failed: $e',
        name: 'PostHogBootstrap',
        error: e,
        stackTrace: st,
      );
    }
  }
}
