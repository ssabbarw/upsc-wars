import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/prelims_countdown.dart';
import 'kill_switch_provider.dart';

part 'prelims_date_provider.g.dart';

/// Remote Config: UPSC Prelims exam date (`YYYY-MM-DD`). Time defaults to 09:30 local.
/// Example: `2027-05-23`
const prelimsDateRemoteConfigKey = 'prelims_date';

const _defaultPrelimsDate = '2026-05-24';

final _dateOnlyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

DateTime _parsePrelimsDate(String raw) {
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

@Riverpod(keepAlive: true)
Future<DateTime> prelimsDate(Ref ref) async {
  if (kIsWeb) return PrelimsCountdown.prelimsDate;
  await ref.watch(killSwitchProvider.future);
  try {
    final raw = FirebaseRemoteConfig.instance
        .getString(prelimsDateRemoteConfigKey)
        .trim();
    return _parsePrelimsDate(raw.isEmpty ? _defaultPrelimsDate : raw);
  } on Object catch (_) {
    return PrelimsCountdown.prelimsDate;
  }
}
