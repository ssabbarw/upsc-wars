import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../daily_war_constants.dart';
import '../data/daily_war_firestore_paths.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_phase_resolver.dart';
import '../domain/daily_war_schedule.dart';
import '../../../core/providers/kill_switch_provider.dart';
import 'server_clock_provider.dart';

part 'daily_war_providers.g.dart';

/// Today's War dateId (IST) using server-corrected clock.
@Riverpod(keepAlive: true)
String dailyWarTodayDateId(Ref ref) {
  final utc = ref.watch(serverNowUtcProvider);
  final ist = DailyWarSchedule.nowIst(utc);
  return DailyWarSchedule.formatIsoDate(DailyWarSchedule.warDateFor(ist));
}

/// Live Firestore snapshot for today's War (null if missing).
@Riverpod(keepAlive: true)
Stream<DailyWarDoc?> dailyWarTodayDoc(Ref ref) {
  final dateId = ref.watch(dailyWarTodayDateIdProvider);
  return DailyWarFirestorePaths.warDoc(dateId).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return DailyWarDoc.fromMap(dateId, snap.data()!);
  });
}

/// Signed-in user's submission for today, if any.
@Riverpod(keepAlive: true)
Stream<DailyWarSubmission?> dailyWarTodaySubmission(Ref ref) {
  final dateId = ref.watch(dailyWarTodayDateIdProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }
  return DailyWarFirestorePaths.submissionDoc(dateId, uid).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return DailyWarSubmission.fromMap(uid, snap.data()!);
  });
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
Stream<DailyWarDoc?> dailyWarYesterdayDoc(Ref ref) {
  final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
  return DailyWarFirestorePaths.warDoc(dateId).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return DailyWarDoc.fromMap(dateId, snap.data()!);
  });
}

@Riverpod(keepAlive: true)
Stream<DailyWarSubmission?> dailyWarYesterdaySubmission(Ref ref) {
  final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }
  return DailyWarFirestorePaths.submissionDoc(dateId, uid).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return DailyWarSubmission.fromMap(uid, snap.data()!);
  });
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

/// One-shot fetch of a War by dateId (History).
@Riverpod(keepAlive: true)
Future<DailyWarDoc?> dailyWarDocById(Ref ref, String dateId) async {
  final snap = await DailyWarFirestorePaths.warDoc(dateId).get();
  if (!snap.exists || snap.data() == null) return null;
  return DailyWarDoc.fromMap(dateId, snap.data()!);
}

/// Recent wars for History (newest first). Limited query.
@Riverpod(keepAlive: true)
Future<List<DailyWarDoc>> dailyWarHistoryList(Ref ref) async {
  const limit = 60;
  final q = await FirebaseFirestore.instance
      .collection(DailyWarFirestorePaths.warsCollection)
      .orderBy(FieldPath.documentId, descending: true)
      .limit(limit)
      .get();
  return q.docs
      .map((d) => DailyWarDoc.fromMap(d.id, d.data()))
      .toList(growable: false);
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
