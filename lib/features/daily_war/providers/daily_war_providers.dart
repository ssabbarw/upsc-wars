import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/daily_war_firestore_paths.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_phase_resolver.dart';
import '../domain/daily_war_schedule.dart';
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
