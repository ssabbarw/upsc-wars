import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kill_switch_provider.g.dart';

/// Remote Config parameter: ISO date `YYYY-MM-DD` (or full ISO). After this
/// calendar day (local time), the home experience shows a mandatory update UI.
const killSwitchDateRemoteConfigKey = 'kill_switch_date';

/// Result of evaluating Remote Config against the device clock.
class KillSwitchSnapshot {
  const KillSwitchSnapshot({
    required this.isActive,
    this.configuredDate,
  });

  /// `true` when today is strictly after [configuredDate].
  final bool isActive;

  /// Parsed kill-switch date from Remote Config, if any.
  final DateTime? configuredDate;

  static const inactive = KillSwitchSnapshot(isActive: false);
}

DateTime? _parseKillDate(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final d = DateTime.tryParse(t);
  if (d != null) {
    return DateTime(d.year, d.month, d.day);
  }
  final parts = t.split(RegExp(r'[-/]'));
  if (parts.length >= 3) {
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (y != null && m != null && day != null) {
      return DateTime(y, m, day);
    }
  }
  return null;
}

@Riverpod(keepAlive: true)
Future<KillSwitchSnapshot> killSwitch(Ref ref) async {
  if (kIsWeb) {
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
      killSwitchDateRemoteConfigKey: '',
    });
    await rc.fetchAndActivate();
    final raw = rc.getString(killSwitchDateRemoteConfigKey);
    final killDay = _parseKillDate(raw);
    if (killDay == null) {
      return KillSwitchSnapshot.inactive;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = today.isAfter(killDay);
    return KillSwitchSnapshot(isActive: active, configuredDate: killDay);
  } on Object catch (_) {
    return KillSwitchSnapshot.inactive;
  }
}
