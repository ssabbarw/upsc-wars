import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';

/// On-device Pulse cache so history and notification taps skip Firestore
/// after the first successful load.
class FomoPulseLocalCache {
  FomoPulseLocalCache({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<({List<FomoPulse> pulses, Map<String, FomoPulseAttemptState> attempts})>
      read() async {
    final prefs = await _ensurePrefs();
    final pulsesRaw = prefs.getString(FomoPulseConstants.cachePulsesKey);
    final attemptsRaw = prefs.getString(FomoPulseConstants.cacheAttemptsKey);
    return (
      pulses: _decodePulses(pulsesRaw),
      attempts: _decodeAttempts(attemptsRaw),
    );
  }

  Future<bool> isListFresh() async {
    final prefs = await _ensurePrefs();
    final syncedAt = prefs.getInt(FomoPulseConstants.cacheListSyncedAtMsKey) ?? 0;
    if (syncedAt <= 0) return false;
    final age = DateTime.now().millisecondsSinceEpoch - syncedAt;
    return age < FomoPulseConstants.historyCacheTtl.inMilliseconds;
  }

  Future<void> writeList({
    required List<FomoPulse> pulses,
    required Map<String, FomoPulseAttemptState> attempts,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      FomoPulseConstants.cachePulsesKey,
      jsonEncode([for (final p in pulses) p.toCacheMap()]),
    );
    await _writeAttempts(prefs, attempts);
    await prefs.setInt(
      FomoPulseConstants.cacheListSyncedAtMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> upsertPulse(FomoPulse pulse) async {
    final current = await read();
    final next = [
      pulse,
      ...current.pulses.where((p) => p.pulseId != pulse.pulseId),
    ]..sort((a, b) {
        final am = a.sentAt?.millisecondsSinceEpoch ?? 0;
        final bm = b.sentAt?.millisecondsSinceEpoch ?? 0;
        return bm.compareTo(am);
      });
    final trimmed = next.take(FomoPulseConstants.historyPageSize).toList();
    final prefs = await _ensurePrefs();
    await prefs.setString(
      FomoPulseConstants.cachePulsesKey,
      jsonEncode([for (final p in trimmed) p.toCacheMap()]),
    );
  }

  Future<void> saveAttempt({
    required String pulseId,
    required FomoPulseAttemptState attempt,
    int? attemptCount,
    int? correctCount,
  }) async {
    final current = await read();
    final attempts = Map<String, FomoPulseAttemptState>.from(current.attempts)
      ..[pulseId] = attempt;
    final prefs = await _ensurePrefs();
    await _writeAttempts(prefs, attempts);

    if (attemptCount == null && correctCount == null) return;
    final pulses = [
      for (final p in current.pulses)
        if (p.pulseId == pulseId)
          p.copyWith(
            attemptCount: attemptCount ?? p.attemptCount,
            correctCount: correctCount ?? p.correctCount,
          )
        else
          p,
    ];
    await prefs.setString(
      FomoPulseConstants.cachePulsesKey,
      jsonEncode([for (final p in pulses) p.toCacheMap()]),
    );
  }

  Future<void> _writeAttempts(
    SharedPreferences prefs,
    Map<String, FomoPulseAttemptState> attempts,
  ) {
    return prefs.setString(
      FomoPulseConstants.cacheAttemptsKey,
      jsonEncode({
        for (final e in attempts.entries)
          if (e.value.attempted) e.key: e.value.toCompactMap(),
      }),
    );
  }

  static List<FomoPulse> _decodePulses(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            FomoPulse.fromCacheMap(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Map<String, FomoPulseAttemptState> _decodeAttempts(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final e in decoded.entries)
          e.key.toString(): FomoPulseAttemptState.fromCompactMap(
            e.value is Map ? Map<String, dynamic>.from(e.value as Map) : null,
          ),
      };
    } catch (_) {
      return const {};
    }
  }
}
