import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/feature_flags.dart';
import '../constants/app_constants.dart';

part 'kill_switch_provider.g.dart';

/// Remote Config: minimum client version (same rules as [ReleaseVersion.parse]).
/// Example: `2.1` means builds below 2.1.0 must update; `2.1.0` is allowed.
const killSwitchVersionRemoteConfigKey = 'kill_switch_version';

/// Remote Config: when `false`, hide the Community shell tab (compile flag must still be on).
const communityTabEnabledRemoteConfigKey = 'community_tab_enabled';

/// Remote Config: max QOTD posts per device in a rolling 24h window (int, default 3; enforced locally).
const qotdMaxPostsPerDayRemoteConfigKey = 'qotd_max_posts_per_day';

/// Result of comparing this build to Remote Config.
class KillSwitchSnapshot {
  const KillSwitchSnapshot({
    required this.isActive,
    this.requiredMinimum,
    this.appVersion,
  });

  /// `true` when this app’s version is **strictly less** than [requiredMinimum].
  final bool isActive;

  /// Parsed Remote Config minimum, if any.
  final ReleaseVersion? requiredMinimum;

  /// Parsed [AppConstants.releaseVersionLabel].
  final ReleaseVersion? appVersion;

  static const inactive = KillSwitchSnapshot(isActive: false);
}

@Riverpod(keepAlive: true)
Future<KillSwitchSnapshot> killSwitch(Ref ref) async {
  if (kIsWeb) {
    return KillSwitchSnapshot.inactive;
  }
  final app = ReleaseVersion.appCurrent;
  if (app == null) {
    return KillSwitchSnapshot.inactive;
  }
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 12),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(minutes: 30),
      ),
    );
    await rc.setDefaults(<String, dynamic>{
      killSwitchVersionRemoteConfigKey: '',
      communityTabEnabledRemoteConfigKey: true,
      qotdMaxPostsPerDayRemoteConfigKey: 3,
      // JSON: { "video_link": "https://...", "message": "...", "version": 1 }
      'home_page_video': '',
    });
    await rc.fetchAndActivate();
    final raw = rc.getString(killSwitchVersionRemoteConfigKey).trim();
    if (raw.isEmpty) {
      return KillSwitchSnapshot(
        isActive: false,
        appVersion: app,
      );
    }
    final required = ReleaseVersion.parse(raw);
    if (required == null) {
      return KillSwitchSnapshot(isActive: false, appVersion: app);
    }
    final active = app.compareTo(required) < 0;
    return KillSwitchSnapshot(
      isActive: active,
      requiredMinimum: required,
      appVersion: app,
    );
  } on Object catch (_) {
    return KillSwitchSnapshot.inactive;
  }
}

/// Whether the Community tab should be shown (after [killSwitchProvider] fetch).
///
/// Fails open (`true`) while loading or on read errors so the tab stays unless RC
/// explicitly disables it. On web, only [FeatureFlags.communityTab] applies.
@Riverpod(keepAlive: true)
Future<bool> communityTabRemoteEnabled(Ref ref) async {
  if (kIsWeb) {
    return FeatureFlags.communityTab;
  }
  if (!FeatureFlags.communityTab) {
    return false;
  }
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance
        .getBool(communityTabEnabledRemoteConfigKey);
  } on Object catch (_) {
    return true;
  }
}
