import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/prelims_countdown.dart';
import 'kill_switch_provider.dart';

part 'prelims_date_provider.g.dart';

/// Remote Config: UPSC Prelims exam date (`YYYY-MM-DD`). Time defaults to 09:30 local.
/// Example: `2027-05-23`
const prelimsDateRemoteConfigKey = 'prelims_date';

const defaultPrelimsDateRemote = '2027-05-23';

final _dateOnlyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Parses `YYYY-MM-DD` into local 09:30; falls back to [PrelimsCountdown.prelimsDate].
DateTime parsePrelimsDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return PrelimsCountdown.prelimsDate;

  final match = _dateOnlyPattern.firstMatch(trimmed);
  if (match != null) {
    final fallback = PrelimsCountdown.prelimsDate;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      fallback.hour,
      fallback.minute,
    );
  }

  return PrelimsCountdown.prelimsDate;
}

/// Reads Remote Config without Riverpod (for notification sync / WorkManager).
DateTime resolvePrelimsDateFromRemoteConfig() {
  if (kIsWeb) return PrelimsCountdown.prelimsDate;
  try {
    final raw = FirebaseRemoteConfig.instance
        .getString(prelimsDateRemoteConfigKey)
        .trim();
    return parsePrelimsDate(raw.isEmpty ? defaultPrelimsDateRemote : raw);
  } on Object catch (_) {
    return PrelimsCountdown.prelimsDate;
  }
}

@Riverpod(keepAlive: true)
Future<DateTime> prelimsDate(Ref ref) async {
  if (kIsWeb) return PrelimsCountdown.prelimsDate;
  await ref.watch(killSwitchProvider.future);
  return resolvePrelimsDateFromRemoteConfig();
}
