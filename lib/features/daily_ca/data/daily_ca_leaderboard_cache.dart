import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_ca_rank_models.dart';

/// Frozen Daily CA boards on disk. Live papers are never stored.
class DailyCaLeaderboardCache {
  DailyCaLeaderboardCache(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'daily_ca_lb_cache_v1';
  static const _maxBoards = 14;

  Map<String, dynamic> _readRaw() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry('$k', v)),
        );
      }
    } on Object {
      // Corrupt — start fresh.
    }
    return {};
  }

  Future<void> _writeRaw(Map<String, dynamic> map) async {
    await _prefs.setString(_key, jsonEncode(map));
  }

  DailyCaLeaderboard? get(String dateId) {
    final raw = _readRaw()[dateId];
    if (raw is! Map) return null;
    return DailyCaLeaderboard.fromMap(dateId, Map<String, dynamic>.from(raw));
  }

  Future<void> putFrozen(DailyCaLeaderboard lb) async {
    if (!lb.isFrozen) return;
    final map = _readRaw();
    map[lb.dateId] = lb.toCacheMap();
    if (map.length > _maxBoards) {
      final keys = map.keys.toList()..sort();
      for (final k in keys.take(map.length - _maxBoards)) {
        map.remove(k);
      }
    }
    await _writeRaw(map);
  }
}
