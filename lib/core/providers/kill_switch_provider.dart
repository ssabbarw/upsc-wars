import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';

part 'kill_switch_provider.g.dart';

/// Remote Config: minimum client version (same rules as [ReleaseVersion.parse]).
/// Example: `2.1` means builds below 2.1.0 must update; `2.1.0` is allowed.
const killSwitchVersionRemoteConfigKey = 'kill_switch_version';

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
