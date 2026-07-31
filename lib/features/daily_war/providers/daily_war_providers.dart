import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../daily_war_constants.dart';
import '../data/daily_war_firestore_paths.dart';
import '../data/daily_war_local_cache.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_phase_resolver.dart';
import '../domain/daily_war_schedule.dart';
import 'server_clock_provider.dart';

part 'daily_war_providers.g.dart';

@Riverpod(keepAlive: true)
Future<DailyWarLocalCache> dailyWarLocalCache(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return DailyWarLocalCache(prefs);
}

/// Today's War dateId (IST) using server-corrected clock.
@Riverpod(keepAlive: true)
String dailyWarTodayDateId(Ref ref) {
  final utc = ref.watch(serverNowUtcProvider);
  final ist = DailyWarSchedule.nowIst(utc);
  return DailyWarSchedule.formatIsoDate(DailyWarSchedule.warDateFor(ist));
}

/// Live Firestore snapshot for today's War (null if missing).
/// Writes through to [DailyWarLocalCache] whenever data arrives.
@Riverpod(keepAlive: true)
Stream<DailyWarDoc?> dailyWarTodayDoc(Ref ref) async* {
  final dateId = ref.watch(dailyWarTodayDateIdProvider);
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final cached = cache.getWar(dateId);
  if (cached != null) yield cached;

  await for (final snap in DailyWarFirestorePaths.warDoc(dateId).snapshots()) {
    if (!snap.exists || snap.data() == null) {
      yield null;
      continue;
    }
    final doc = DailyWarDoc.fromMap(dateId, snap.data()!);
    unawaited(cache.putWar(doc));
    yield doc;
  }
}

/// Signed-in user's submission for today, if any.
@Riverpod(keepAlive: true)
Stream<DailyWarSubmission?> dailyWarTodaySubmission(Ref ref) async* {
  final dateId = ref.watch(dailyWarTodayDateIdProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    yield null;
    return;
  }
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final cached = cache.getSubmission(uid, dateId);
  if (cached != null) yield cached;

  await for (final snap
      in DailyWarFirestorePaths.submissionDoc(dateId, uid).snapshots()) {
    if (!snap.exists || snap.data() == null) {
      yield null;
      continue;
    }
    final sub = DailyWarSubmission.fromMap(uid, snap.data()!);
    unawaited(cache.putSubmission(uid, sub, dateId));
    yield sub;
  }
}

/// Combined home-hero view model for today's War.
class DailyWarHomeSnapshot {
  const DailyWarHomeSnapshot({
    required this.dateId,
    required this.phase,
    required this.istNow,
    this.doc,
    this.submission,
  });

  final String dateId;
  final DailyWarPhase phase;
  final DateTime istNow;
  final DailyWarDoc? doc;
  final DailyWarSubmission? submission;

  /// Tonight's War still pending for this user (drives streak crimson tick).
  bool get warUnplayed => submission == null;
}

/// Yesterday's War for the H7 missed strip + last-night social proof.
class DailyWarYesterdaySnapshot {
  const DailyWarYesterdaySnapshot({
    required this.dateId,
    this.doc,
    this.submission,
  });

  final String dateId;
  final DailyWarDoc? doc;
  final DailyWarSubmission? submission;

  bool get shouldShowMissedStrip =>
      doc != null &&
      doc!.questionsVisible &&
      submission == null;
}

@Riverpod(keepAlive: true)
DailyWarHomeSnapshot dailyWarHomeSnapshot(Ref ref) {
  final utc = ref.watch(serverNowUtcProvider);
  final ist = DailyWarSchedule.nowIst(utc);
  final dateId = DailyWarSchedule.formatIsoDate(
    DailyWarSchedule.warDateFor(ist),
  );
  final doc = ref.watch(dailyWarTodayDocProvider).asData?.value;
  final submission = ref.watch(dailyWarTodaySubmissionProvider).asData?.value;
  final phase = DailyWarPhaseResolver.resolve(
    referenceIst: ist,
    firestoreStatus: doc?.status,
    ranksReady: doc?.ranksReady ?? false,
    questionCount: doc?.questionCount ??
        DailyWarSchedule.questionCountForDate(
          DailyWarSchedule.warDateFor(ist),
        ),
  );
  return DailyWarHomeSnapshot(
    dateId: dateId,
    phase: phase,
    istNow: ist,
    doc: doc,
    submission: submission,
  );
}

@Riverpod(keepAlive: true)
String dailyWarYesterdayDateId(Ref ref) {
  final utc = ref.watch(serverNowUtcProvider);
  final ist = DailyWarSchedule.nowIst(utc);
  final yesterday = DailyWarSchedule.warDateFor(ist).subtract(
    const Duration(days: 1),
  );
  return DailyWarSchedule.formatIsoDate(yesterday);
}

@Riverpod(keepAlive: true)
Stream<DailyWarDoc?> dailyWarYesterdayDoc(Ref ref) async* {
  final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final cached = cache.getWar(dateId);
  if (cached != null) yield cached;

  await for (final snap in DailyWarFirestorePaths.warDoc(dateId).snapshots()) {
    if (!snap.exists || snap.data() == null) {
      yield null;
      continue;
    }
    final doc = DailyWarDoc.fromMap(dateId, snap.data()!);
    unawaited(cache.putWar(doc));
    yield doc;
  }
}

@Riverpod(keepAlive: true)
Stream<DailyWarSubmission?> dailyWarYesterdaySubmission(Ref ref) async* {
  final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    yield null;
    return;
  }
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final cached = cache.getSubmission(uid, dateId);
  if (cached != null) yield cached;

  await for (final snap
      in DailyWarFirestorePaths.submissionDoc(dateId, uid).snapshots()) {
    if (!snap.exists || snap.data() == null) {
      yield null;
      continue;
    }
    final sub = DailyWarSubmission.fromMap(uid, snap.data()!);
    unawaited(cache.putSubmission(uid, sub, dateId));
    yield sub;
  }
}

@Riverpod(keepAlive: true)
DailyWarYesterdaySnapshot dailyWarYesterdaySnapshot(Ref ref) {
  final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
  final doc = ref.watch(dailyWarYesterdayDocProvider).asData?.value;
  final submission =
      ref.watch(dailyWarYesterdaySubmissionProvider).asData?.value;
  return DailyWarYesterdaySnapshot(
    dateId: dateId,
    doc: doc,
    submission: submission,
  );
}

/// One-shot fetch of a War by dateId (History / results) — prefers local cache.
@Riverpod(keepAlive: true)
Future<DailyWarDoc?> dailyWarDocById(Ref ref, String dateId) async {
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final today = ref.watch(dailyWarTodayDateIdProvider);
  return cache.getWarPreferCache(dateId, todayDateId: today);
}

/// Recent wars for History — cache-first, selective Firestore refresh.
@Riverpod(keepAlive: true)
Future<DailyWarHistoryBundle> dailyWarHistoryBundle(Ref ref) async {
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return cache.loadHistory(uid: uid);
}

/// Full archive for one War night (leaderboard + attempt). Local-only once ranked.
@Riverpod()
Future<DailyWarArchiveBundle> dailyWarArchive(Ref ref, String dateId) async {
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return cache.loadArchive(dateId: dateId, uid: uid);
}

/// Questions for a War paper with the user's answers overlaid (local SQLite).
@Riverpod()
Future<List<TestQuestion>> dailyWarArchiveQuestions(
  Ref ref,
  String dateId,
) async {
  final archive = await ref.watch(dailyWarArchiveProvider(dateId).future);
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  final answers = archive.submission?.answers ?? const <String, String>{};
  final out = <TestQuestion>[];
  for (final uuid in archive.war.questionUuids) {
    final q = await repo.loadStandaloneQuestionByUuid(uuid);
    if (q == null) continue;
    final selected = answers[uuid];
    var status = 'unattempted';
    if (selected != null && selected.isNotEmpty) {
      status = selected == q.correctOption.toLowerCase() ? 'correct' : 'wrong';
    }
    out.add(q.copyWith(selectedOption: selected, status: status));
  }
  return out;
}

/// @deprecated Prefer [dailyWarHistoryBundleProvider] (includes submissions).
@Riverpod(keepAlive: true)
Future<List<DailyWarDoc>> dailyWarHistoryList(Ref ref) async {
  final bundle = await ref.watch(dailyWarHistoryBundleProvider.future);
  return bundle.wars;
}

/// Cheap social counts from RTDB (`lobby` / `writing`).
///
/// Polled on an RC-controlled interval ([dailyWarLiveCountPollSecondsRemote])
/// **only** during lobby / live phases. Auto-dispose so polling stops when
/// nothing watches.
class DailyWarLiveCounts {
  const DailyWarLiveCounts({required this.lobby, required this.writing});

  const DailyWarLiveCounts.empty() : lobby = 0, writing = 0;

  final int lobby;
  final int writing;
}

@Riverpod()
Stream<DailyWarLiveCounts> dailyWarLiveCounts(Ref ref) async* {
  if (kIsWeb) {
    yield const DailyWarLiveCounts.empty();
    return;
  }

  final snap = ref.watch(dailyWarHomeSnapshotProvider);
  final pollSeconds =
      ref.watch(dailyWarLiveCountPollSecondsRemoteProvider).asData?.value ??
          DailyWarConstants.liveCountPollSeconds;
  final phase = snap.phase;
  final dateId = snap.dateId;
  final shouldPoll = phase == DailyWarPhase.lobby ||
      phase == DailyWarPhase.liveJoinable ||
      phase == DailyWarPhase.liveLocked;

  if (!shouldPoll || dateId.isEmpty) {
    yield const DailyWarLiveCounts.empty();
    return;
  }

  final path = '${DailyWarConstants.rtdbCountsRoot}/$dateId';
  final dbRef = FirebaseDatabase.instance.ref(path);

  while (true) {
    try {
      final s = await dbRef.get();
      final v = s.value;
      if (v is Map) {
        final map = Map<Object?, Object?>.from(v);
        yield DailyWarLiveCounts(
          lobby: (map['lobby'] as num?)?.toInt() ?? 0,
          writing: (map['writing'] as num?)?.toInt() ?? 0,
        );
      } else {
        yield const DailyWarLiveCounts.empty();
      }
    } on Object {
      yield const DailyWarLiveCounts.empty();
    }
    // Re-read RC each tick so Console changes apply without restarting the app.
    final secs =
        ref.read(dailyWarLiveCountPollSecondsRemoteProvider).asData?.value ??
            pollSeconds;
    await Future<void>.delayed(Duration(seconds: secs));
  }
}
