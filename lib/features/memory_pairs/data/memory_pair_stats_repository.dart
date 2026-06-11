import 'dart:convert';

import '../../../core/providers/prefs_provider.dart';
import '../domain/memory_pair_models.dart';

/// Local play stats persisted in SharedPreferences (v1).
class MemoryPairStatsRepository {
  MemoryPairStatsRepository(this._prefs);

  static const _prefsKey = 'memory_pair_set_stats_v1';

  final PrefsService _prefs;

  Map<String, dynamic> _readAll() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', v));
      }
    } on Object {
      return {};
    }
    return {};
  }

  Future<void> _writeAll(Map<String, dynamic> data) async {
    await _prefs.setString(_prefsKey, jsonEncode(data));
  }

  String _key(String setId, MemoryPairDifficulty difficulty) =>
      '$setId:${difficulty.id}';

  Future<MemoryPairSetStats?> getStats(
    String setId,
    MemoryPairDifficulty difficulty,
  ) async {
    final all = _readAll();
    final entry = all[_key(setId, difficulty)];
    if (entry is! Map) return null;
    final best = entry['bestSeconds'];
    final lastAt = entry['lastPlayedAt'];
    return MemoryPairSetStats(
      setId: setId,
      difficulty: difficulty,
      bestSeconds: best is int ? best : (best is num ? best.round() : null),
      lastErrors: entry['lastErrors'] is int
          ? entry['lastErrors'] as int
          : (entry['lastErrors'] as num?)?.round() ?? 0,
      lastPlayedAt: lastAt is String ? DateTime.tryParse(lastAt) : null,
    );
  }

  Future<int?> bestSecondsForSet(String setId) async {
    final all = _readAll();
    int? best;
    for (final entry in all.entries) {
      if (!entry.key.startsWith('$setId:')) continue;
      final map = entry.value;
      if (map is! Map) continue;
      final sec = map['bestSeconds'];
      final n = sec is int ? sec : (sec is num ? sec.round() : null);
      if (n != null && (best == null || n < best)) best = n;
    }
    return best;
  }

  Future<DateTime?> lastPlayedForSet(String setId) async {
    final all = _readAll();
    DateTime? last;
    for (final entry in all.entries) {
      if (!entry.key.startsWith('$setId:')) continue;
      final map = entry.value;
      if (map is! Map) continue;
      final at = map['lastPlayedAt'];
      if (at is! String) continue;
      final dt = DateTime.tryParse(at);
      if (dt != null && (last == null || dt.isAfter(last))) last = dt;
    }
    return last;
  }

  Future<bool> recordResult({
    required String setId,
    required MemoryPairDifficulty difficulty,
    required MemoryPairGameResult result,
  }) async {
    final all = Map<String, dynamic>.from(_readAll());
    final key = _key(setId, difficulty);
    final existing = all[key];
    Map<String, dynamic> prev = {};
    if (existing is Map) {
      prev = Map<String, dynamic>.from(existing);
    }
    final prevBest = prev['bestSeconds'];
    final prevBestInt = prevBest is int
        ? prevBest
        : (prevBest is num ? prevBest.round() : null);
    final isBest = prevBestInt == null || result.seconds < prevBestInt;
    final playedAt = DateTime.now().toUtc().toIso8601String();

    all[key] = {
      'bestSeconds': isBest ? result.seconds : prevBestInt,
      'lastErrors': result.errors,
      'lastPlayedAt': playedAt,
    };
    await _writeAll(all);
    return isBest;
  }
}
