import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Remote Config: when `false`, skip all Firestore writes for admin dashboard
/// metrics (reads on the super-user dashboard still work).
const adminDashboardCollectionEnabledRemoteConfigKey =
    'admin_dashboard_collection_enabled';

/// Whether client-side admin dashboard **collection** is enabled.
///
/// Defaults to `true` when Remote Config is unavailable or not yet fetched.
bool isAdminDashboardCollectionEnabled() {
  try {
    return FirebaseRemoteConfig.instance.getBool(
      adminDashboardCollectionEnabledRemoteConfigKey,
    );
  } on Object catch (_) {
    return true;
  }
}
