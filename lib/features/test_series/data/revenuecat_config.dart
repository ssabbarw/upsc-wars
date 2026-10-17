/// RevenueCat configuration.
///
/// The Android **public SDK key** (starts with `goog_`) is not a secret, but it
/// is read from a build-time define so it stays out of source control:
///
///   flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxx
///   flutter build appbundle --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxx
///
/// If it is empty, purchases are disabled (the paywall explains this) but the
/// rest of the app keeps working.
abstract final class RevenueCatConfig {
  RevenueCatConfig._();

  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  static bool get isConfigured => androidApiKey.isNotEmpty;
}
