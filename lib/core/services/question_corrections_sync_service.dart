import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/question_bank_upsert.dart';
import '../database/user_db.dart';
import '../providers/kill_switch_provider.dart';
import '../providers/prefs_provider.dart';
import '../../features/question_editor/data/question_correction_mapper.dart';
import '../../features/question_editor/data/question_corrections_firestore.dart';

/// Downloads `question_corrections/active` when Remote Config revision bumps.
class QuestionCorrectionsSyncService {
  QuestionCorrectionsSyncService({
    required UserDatabase userDb,
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       _upsert = QuestionBankUpsert(userDb);

  final SharedPreferences _prefs;
  final QuestionBankUpsert _upsert;

  static const syncInterval = Duration(hours: 24);

  int get localRevision =>
      _prefs.getInt(PrefKeys.questionCorrectionsRevision) ?? 0;

  int? get lastSyncedAtMs =>
      _prefs.getInt(PrefKeys.questionCorrectionsSyncedAtMs);

  bool shouldSyncNow({DateTime? now}) {
    final last = lastSyncedAtMs;
    if (last == null) return true;
    final clock = now ?? DateTime.now();
    final elapsed = clock.difference(DateTime.fromMillisecondsSinceEpoch(last));
    return elapsed >= syncInterval;
  }

  /// Returns number of corrections applied, or 0 if skipped / nothing new.
  Future<int> syncIfNeeded({bool force = false}) async {
    if (kIsWeb) return 0;
    if (!force && !shouldSyncNow()) return 0;

    try {
      final remoteRevision = _readRemoteConfigRevision();
      final rcHintsNewData =
          remoteRevision > localRevision && remoteRevision > 0;
      if (!force && !rcHintsNewData) {
        // Remote Config is an optional fast-path; still check Firestore at most
        // once per [syncInterval] so corrections publish without an RC bump.
      }

      final snap = await QuestionCorrectionsFirestore.activeDoc().get();
      if (!snap.exists) {
        await _touchSyncedAt();
        return 0;
      }

      final data = snap.data();
      if (data == null) {
        await _touchSyncedAt();
        return 0;
      }

      final activeRevision = QuestionCorrectionMapper.readActiveRevision(data);
      if (activeRevision <= localRevision) {
        await _touchSyncedAt();
        return 0;
      }

      final maps = QuestionCorrectionMapper.parseActiveCorrections(data);
      if (maps.isEmpty) {
        await _prefs.setInt(
          PrefKeys.questionCorrectionsRevision,
          activeRevision,
        );
        await _touchSyncedAt();
        return 0;
      }

      await _upsert.applyCorrections(maps);
      await _prefs.setInt(PrefKeys.questionCorrectionsRevision, activeRevision);
      await _touchSyncedAt();
      return maps.length;
    } catch (e, st) {
      debugPrint('QuestionCorrectionsSyncService.syncIfNeeded: $e');
      debugPrintStack(stackTrace: st);
      return 0;
    }
  }

  int _readRemoteConfigRevision() {
    try {
      return FirebaseRemoteConfig.instance.getInt(
        questionCorrectionsRevisionRemoteConfigKey,
      );
    } on Object catch (_) {
      return 0;
    }
  }

  Future<void> _touchSyncedAt() async {
    await _prefs.setInt(
      PrefKeys.questionCorrectionsSyncedAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// After a local publish, mark revision without waiting for daily sync.
  Future<void> markRevisionApplied(int revision) async {
    await _prefs.setInt(PrefKeys.questionCorrectionsRevision, revision);
    await _touchSyncedAt();
  }
}
