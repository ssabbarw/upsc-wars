/// PostHog configuration from build-time defines.
///
/// Project API key (public write-only token) and host:
///
///   flutter run --dart-define=POSTHOG_API_KEY=phc_xxxxxxxx
///   flutter run --dart-define=POSTHOG_HOST=https://us.i.posthog.com
///
/// Or via `--dart-define-from-file=dart_defines.json`.
///
/// If [apiKey] is empty, PostHog stays disabled and the rest of the app works.
abstract final class PostHogAppConfig {
  PostHogAppConfig._();

  static const String apiKey = String.fromEnvironment('POSTHOG_API_KEY');

  /// US cloud by default. Use `https://eu.i.posthog.com` for EU projects.
  static const String host = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  static bool get isConfigured => apiKey.isNotEmpty;
}
