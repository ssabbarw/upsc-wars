import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/app_constants.dart';
import 'kill_switch_provider.dart';
import 'package_info_provider.dart';
import 'prefs_provider.dart';

/// Remote Config: optional minimum for a dismissible “please update” banner.
/// Same version format as [killSwitchVersionRemoteConfigKey] (`3.2` or `v3.2`).
const softUpdateVersionRemoteConfigKey = 'soft_update_version';

/// Remote Config: optional banner body. Empty uses [SoftUpdateSnapshot.defaultMessage].
const softUpdateMessageRemoteConfigKey = 'soft_update_message';

class SoftUpdateSnapshot {
  const SoftUpdateSnapshot({
    required this.shouldPrompt,
    this.requiredMinimum,
    this.message = defaultMessage,
  });

  static const defaultMessage =
      'Update to get CA Shots, the Daily Current Affairs Test, and Daily Battle.';

  final bool shouldPrompt;
  final ReleaseVersion? requiredMinimum;
  final String message;

  static const hidden = SoftUpdateSnapshot(shouldPrompt: false);
}

/// Pure visibility rule — used by [softUpdateProvider] and unit tests.
SoftUpdateSnapshot resolveSoftUpdate({
  required bool killSwitchActive,
  required ReleaseVersion? appVersion,
  required String rawRequired,
  required String rawMessage,
  required String dismissedVersion,
}) {
  if (killSwitchActive) return SoftUpdateSnapshot.hidden;
  final app = appVersion;
  if (app == null) return SoftUpdateSnapshot.hidden;
  final required = ReleaseVersion.parse(rawRequired);
  if (required == null) return SoftUpdateSnapshot.hidden;
  if (app.compareTo(required) >= 0) return SoftUpdateSnapshot.hidden;
  if (dismissedVersion == required.toString()) {
    return SoftUpdateSnapshot.hidden;
  }
  final message = rawMessage.trim();
  return SoftUpdateSnapshot(
    shouldPrompt: true,
    requiredMinimum: required,
    message: message.isEmpty ? SoftUpdateSnapshot.defaultMessage : message,
  );
}

/// Dismissible store nudge when this build is behind [softUpdateVersionRemoteConfigKey]
/// but still allowed through the kill switch.
final softUpdateProvider = FutureProvider<SoftUpdateSnapshot>((ref) async {
  if (kIsWeb) return SoftUpdateSnapshot.hidden;
  final kill = await ref.watch(killSwitchProvider.future);
  final prefs = await ref.watch(prefsServiceProvider.future);
  final pkg = await ref.watch(packageInfoProvider.future);
  try {
    final rc = FirebaseRemoteConfig.instance;
    return resolveSoftUpdate(
      killSwitchActive: kill.isActive,
      appVersion: releaseVersionFromPackageInfo(pkg),
      rawRequired: rc.getString(softUpdateVersionRemoteConfigKey),
      rawMessage: rc.getString(softUpdateMessageRemoteConfigKey),
      dismissedVersion: prefs.softUpdateDismissedVersion,
    );
  } on Object catch (_) {
    return SoftUpdateSnapshot.hidden;
  }
});
