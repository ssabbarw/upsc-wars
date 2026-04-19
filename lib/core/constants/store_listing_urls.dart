/// Public store listing URLs for rate / update flows.
///
/// Set [appStore] to your App Store product page when available.
abstract final class StoreListingUrls {
  StoreListingUrls._();

  /// Google Play listing (package from `android/app/build.gradle.kts`).
  static const String playStore =
      'https://play.google.com/store/apps/details?id=practice.upsc.indiaapps.com.upscmcqpractice';

  /// Apple App Store product URL (e.g. `https://apps.apple.com/app/id…`).
  static const String appStore = '';
}
