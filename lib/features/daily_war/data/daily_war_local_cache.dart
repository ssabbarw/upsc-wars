import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';
import 'daily_war_firestore_paths.dart';

/// Disk cache for Daily War public docs + the signed-in user's submissions.
///
/// Ranked / closed papers are treated as immutable and are not re-fetched.
/// Recent (today + last ~14 days) docs are refreshed lightly so live status
/// still updates without reloading the full history every open.
class DailyWarLocalCache {
  DailyWarLocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const _warsKey = 'daily_war_cache_wars_v1';
  static const _subsPrefix = 'daily_war_cache_subs_v1_';
  static const _lbKey = 'daily_war_cache_lb_v1';
  static const _archiveReadyKey = 'daily_war_cache_archive_ready_v1';
  static const _historyMetaKey = 'daily_war_cache_history_meta_v1';

  /// How many newest calendar days to always reconcile with Firestore.
  static const recentRefreshDays = 14;

  static const historyLimit = 60;

  Map<String, dynamic> _readWarsRaw() {
    final raw = _prefs.getString(_warsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry('$k', v)),
        );
      }
    } on Object {
      // Corrupt cache — start fresh.
    }
    return {};
  }

  Future<void> _writeWarsRaw(Map<String, dynamic> map) async {
    await _prefs.setString(_warsKey, jsonEncode(map));
  }

  Map<String, dynamic> _readSubsRaw(String uid) {
    final raw = _prefs.getString('$_subsPrefix$uid');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry('$k', v)),
        );
      }
    } on Object {
      // ignore
    }
    return {};
  }

  Future<void> _writeSubsRaw(String uid, Map<String, dynamic> map) async {
    await _prefs.setString('$_subsPrefix$uid', jsonEncode(map));
  }

  DailyWarDoc? getWar(String dateId) {
    final raw = _readWarsRaw()[dateId];
    if (raw is! Map) return null;
    return DailyWarDoc.fromMap(dateId, Map<String, dynamic>.from(raw));
  }

  Future<void> putWar(DailyWarDoc doc) async {
    final map = _readWarsRaw();
    map[doc.dateId] = {
      ...doc.toCacheMap(),
      '_cached_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
    await _writeWarsRaw(map);
  }

  DailyWarSubmission? getSubmission(String uid, String dateId) {
    if (uid.isEmpty) return null;
    final raw = _readSubsRaw(uid)[dateId];
    if (raw is! Map) return null;
    if (raw['_absent'] == true) return null;
    return DailyWarSubmission.fromMap(uid, Map<String, dynamic>.from(raw));
  }

  /// Whether we already know there is no submission for this war (stable miss).
  bool hasKnownAbsence(String uid, String dateId) {
    if (uid.isEmpty) return false;
    final raw = _readSubsRaw(uid)[dateId];
    return raw is Map && raw['_absent'] == true;
  }

  Future<void> putSubmission(
    String uid,
    DailyWarSubmission sub,
    String dateId,
  ) async {
    if (uid.isEmpty) return;
    final map = _readSubsRaw(uid);
    map[dateId] = {
      ...sub.toCacheMap(),
      '_cached_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
    await _writeSubsRaw(uid, map);
  }

  Future<void> putSubmissionAbsent(String uid, String dateId) async {
    if (uid.isEmpty) return;
    final map = _readSubsRaw(uid);
    map[dateId] = {
      '_absent': true,
      '_cached_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
    await _writeSubsRaw(uid, map);
  }

  Map<String, dynamic> _readLbRaw() {
    final raw = _prefs.getString(_lbKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry('$k', v)),
        );
      }
    } on Object {
      // ignore
    }
    return {};
  }

  Future<void> _writeLbRaw(Map<String, dynamic> map) async {
    await _prefs.setString(_lbKey, jsonEncode(map));
  }

  DailyWarLeaderboard? getLeaderboard(String dateId) {
    final raw = _readLbRaw()[dateId];
    if (raw is! Map) return null;
    return DailyWarLeaderboard.fromMap(dateId, Map<String, dynamic>.from(raw));
  }

  Future<void> putLeaderboard(DailyWarLeaderboard lb) async {
    final map = _readLbRaw();
    map[lb.dateId] = {
      ...lb.toCacheMap(),
      '_cached_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
    await _writeLbRaw(map);
  }

  Set<String> _readArchiveReady() {
    final raw = _prefs.getString(_archiveReadyKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => '$e').toSet();
      }
    } on Object {
      // ignore
    }
    return {};
  }

  Future<void> markArchiveReady(String dateId) async {
    final set = _readArchiveReady()..add(dateId);
    await _prefs.setString(_archiveReadyKey, jsonEncode(set.toList()));
  }

  bool isArchiveReady(String dateId) => _readArchiveReady().contains(dateId);

  /// Full archive for detail screen. Once ranked + hydrated, never hits Firestore.
  Future<DailyWarArchiveBundle> loadArchive({
    required String dateId,
    required String uid,
  }) async {
    final today = DailyWarSchedule.formatIsoDate(
      DailyWarSchedule.warDateFor(DailyWarSchedule.nowIst()),
    );
    var war = await getWarPreferCache(dateId, todayDateId: today);
    if (war == null) {
      throw StateError('War $dateId not found');
    }
    DailyWarDoc resolved = war;

    final localOnly = resolved.ranksReady && isArchiveReady(dateId);

    DailyWarLeaderboard? lb = getLeaderboard(dateId);
    if (!localOnly && resolved.ranksReady && lb == null) {
      try {
        final snap =
            await DailyWarFirestorePaths.leaderboardDoc(dateId).get();
        if (snap.exists && snap.data() != null) {
          lb = DailyWarLeaderboard.fromMap(dateId, snap.data()!);
          await putLeaderboard(lb);
        }
      } on Object {
        // keep null
      }
    }

    DailyWarSubmission? sub;
    if (uid.isNotEmpty) {
      sub = getSubmission(uid, dateId);
      final knownAbsent = hasKnownAbsence(uid, dateId);
      final needsAnswers = sub != null && sub.answers.isEmpty && !localOnly;
      if (!localOnly &&
          ((sub == null && !knownAbsent) || needsAnswers)) {
        try {
          final snap =
              await DailyWarFirestorePaths.submissionDoc(dateId, uid).get();
          if (snap.exists && snap.data() != null) {
            sub = DailyWarSubmission.fromMap(uid, snap.data()!);
            await putSubmission(uid, sub, dateId);
          } else if (resolved.isStableArchive) {
            await putSubmissionAbsent(uid, dateId);
            sub = null;
          }
        } on Object {
          // keep cached
        }
      }
    }

    // Refresh war once more if we just learned it's ranked but cache was stale.
    if (!localOnly && !resolved.ranksReady) {
      try {
        final snap = await DailyWarFirestorePaths.warDoc(dateId).get();
        if (snap.exists && snap.data() != null) {
          resolved = DailyWarDoc.fromMap(dateId, snap.data()!);
          await putWar(resolved);
        }
      } on Object {
        // keep
      }
    }

    // Only freeze locally once ranks + leaderboard + attempt (with answers) are in.
    final attemptHydrated = uid.isEmpty ||
        hasKnownAbsence(uid, dateId) ||
        (sub != null &&
            (sub.answers.isNotEmpty || (sub.correct + sub.wrong) == 0));
    if (resolved.ranksReady && lb != null && attemptHydrated) {
      await markArchiveReady(dateId);
    }

    return DailyWarArchiveBundle(
      war: resolved,
      submission: sub,
      leaderboard: lb,
      fromLocalOnly:
          localOnly || (resolved.ranksReady && isArchiveReady(dateId)),
    );
  }

  List<DailyWarDoc> cachedWarsNewestFirst({int limit = historyLimit}) {
    final map = _readWarsRaw();
    final ids = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final out = <DailyWarDoc>[];
    for (final id in ids) {
      if (out.length >= limit) break;
      final raw = map[id];
      if (raw is! Map) continue;
      out.add(DailyWarDoc.fromMap(id, Map<String, dynamic>.from(raw)));
    }
    return out;
  }

  /// History with cache-first + selective network refresh.
  Future<DailyWarHistoryBundle> loadHistory({required String uid}) async {
    final cached = cachedWarsNewestFirst();
    final byId = <String, DailyWarDoc>{
      for (final w in cached) w.dateId: w,
    };

    // Always pull a small newest page so brand-new wars appear without a full 60-read.
    QuerySnapshot<Map<String, dynamic>>? recentSnap;
    try {
      recentSnap = await FirebaseFirestore.instance
          .collection(DailyWarFirestorePaths.warsCollection)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(recentRefreshDays + 2)
          .get();
    } on Object {
      // Offline — serve cache only.
      return _bundleFromMaps(byId, uid, limit: historyLimit);
    }

    for (final d in recentSnap.docs) {
      final doc = DailyWarDoc.fromMap(d.id, d.data());
      byId[doc.dateId] = doc;
      await putWar(doc);
    }

    // If cache is thin, do one fuller query once, then rely on disk.
    if (byId.length < 20) {
      try {
        final full = await FirebaseFirestore.instance
            .collection(DailyWarFirestorePaths.warsCollection)
            .orderBy(FieldPath.documentId, descending: true)
            .limit(historyLimit)
            .get();
        for (final d in full.docs) {
          final doc = DailyWarDoc.fromMap(d.id, d.data());
          byId[doc.dateId] = doc;
          await putWar(doc);
        }
      } on Object {
        // keep partial
      }
    }

    await _prefs.setString(
      _historyMetaKey,
      jsonEncode({
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
        'count': byId.length,
      }),
    );

    return _bundleFromMaps(byId, uid, limit: historyLimit);
  }

  Future<DailyWarHistoryBundle> _bundleFromMaps(
    Map<String, DailyWarDoc> byId,
    String uid, {
    required int limit,
  }) async {
    final wars = byId.values.toList()
      ..sort((a, b) => b.dateId.compareTo(a.dateId));
    final trimmed = wars.take(limit).toList(growable: false);

    final subs = <String, DailyWarSubmission>{};
    if (uid.isNotEmpty) {
      final todayIst = DailyWarSchedule.formatIsoDate(
        DailyWarSchedule.warDateFor(DailyWarSchedule.nowIst()),
      );
      for (final w in trimmed) {
        final cached = getSubmission(uid, w.dateId);
        if (cached != null &&
            (cached.hasOfficialRank ||
                cached.mode == 'unranked' ||
                w.isStableArchive)) {
          subs[w.dateId] = cached;
          continue;
        }
        // Known miss on a finished past war — don't hit Firestore again.
        if (hasKnownAbsence(uid, w.dateId) &&
            w.isStableArchive &&
            w.dateId.compareTo(todayIst) < 0) {
          continue;
        }
        try {
          final snap =
              await DailyWarFirestorePaths.submissionDoc(w.dateId, uid).get();
          if (snap.exists && snap.data() != null) {
            final sub = DailyWarSubmission.fromMap(uid, snap.data()!);
            subs[w.dateId] = sub;
            await putSubmission(uid, sub, w.dateId);
          } else if (w.isStableArchive && w.dateId.compareTo(todayIst) < 0) {
            await putSubmissionAbsent(uid, w.dateId);
          }
        } on Object {
          if (cached != null) subs[w.dateId] = cached;
        }
      }
    }

    return DailyWarHistoryBundle(wars: trimmed, submissions: subs);
  }

  /// One-shot war fetch with cache for stable archives.
  Future<DailyWarDoc?> getWarPreferCache(
    String dateId, {
    String? todayDateId,
  }) async {
    final cached = getWar(dateId);
    final today = todayDateId ??
        DailyWarSchedule.formatIsoDate(
          DailyWarSchedule.warDateFor(DailyWarSchedule.nowIst()),
        );
    if (cached != null &&
        cached.isStableArchive &&
        dateId.compareTo(today) < 0) {
      return cached;
    }
    try {
      final snap = await DailyWarFirestorePaths.warDoc(dateId).get();
      if (!snap.exists || snap.data() == null) return cached;
      final doc = DailyWarDoc.fromMap(dateId, snap.data()!);
      await putWar(doc);
      return doc;
    } on Object {
      return cached;
    }
  }
}

class DailyWarHistoryBundle {
  const DailyWarHistoryBundle({
    required this.wars,
    required this.submissions,
  });

  final List<DailyWarDoc> wars;
  final Map<String, DailyWarSubmission> submissions;
}

/// War night archive for the detail screen (leaderboard + attempt).
class DailyWarArchiveBundle {
  const DailyWarArchiveBundle({
    required this.war,
    required this.submission,
    required this.leaderboard,
    required this.fromLocalOnly,
  });

  final DailyWarDoc war;
  final DailyWarSubmission? submission;
  final DailyWarLeaderboard? leaderboard;
  final bool fromLocalOnly;
}
