import 'dart:convert';

import '../../../core/providers/prefs_provider.dart';
import '../domain/qotd_models.dart';

/// Rolling 24h QOTD post cap stored on-device ([PrefsService.qotdLocalPostEpochsMsJson]).
abstract final class QotdLocalPostLimit {
  QotdLocalPostLimit._();

  static const _window = Duration(hours: 24);

  static List<int> _parseAndPrune(PrefsService prefs, int nowMs) {
    final cut = nowMs - _window.inMilliseconds;
    final raw = prefs.qotdLocalPostEpochsMsJson;
    List<int> list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        list = <int>[];
      } else {
        list = decoded
            .map((e) => (e as num).toInt())
            .where((e) => e >= cut)
            .toList();
        list.sort();
      }
    } on Object catch (_) {
      list = <int>[];
    }
    final encoded = jsonEncode(list);
    if (encoded != raw) {
      prefs.qotdLocalPostEpochsMsJson = encoded;
    }
    return list;
  }

  /// How many QOTD posts this device recorded in the last 24 hours.
  static int rolling24hCount(PrefsService prefs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _parseAndPrune(prefs, now).length;
  }

  /// Throws [QotdDailyLimitExceeded] when [maxPerWindow] is exceeded (<=0 disables).
  static void assertCanPost(PrefsService prefs, int maxPerWindow) {
    if (maxPerWindow <= 0) return;
    if (rolling24hCount(prefs) >= maxPerWindow) {
      throw QotdDailyLimitExceeded(maxPerWindow);
    }
  }

  /// Call after Firestore [QotdRepository.createPost] succeeds.
  static void recordPost(PrefsService prefs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = _parseAndPrune(prefs, now)..add(now);
    prefs.qotdLocalPostEpochsMsJson = jsonEncode(list);
  }
}
