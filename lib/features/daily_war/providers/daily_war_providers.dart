import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../daily_war_constants.dart';
import '../data/daily_war_firestore_paths.dart';
import '../data/daily_war_local_cache.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_phase_resolver.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/daily_war_streak.dart';
import 'server_clock_provider.dart';

part 'daily_war_providers.g.dart';

/// Dedupes concurrent Firestore reads for the same public war [dateId].
final _warDocInflight = <String, Future<DailyWarDoc?>>{};

@Riverpod(keepAlive: true)
Future<DailyWarLocalCache> dailyWarLocalCache(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return DailyWarLocalCache(prefs);
}

/// Today's War dateId (IST) using server-corrected clock.
///
/// Watches the UI tick so the date rolls over at midnight while the app stays
/// open — the RTDB offset stream can go a whole night without emitting. The
/// returned String dedupes, so dependents only rebuild on an actual new day.
@Riverpod(keepAlive: true)
String dailyWarTodayDateId(Ref ref) {
  ref.watch(dailyWarUiTickProvider);
  final utc = ref.watch(serverNowUtcProvider);
  final ist = DailyWarSchedule.nowIst(utc);
  return DailyWarSchedule.formatIsoDate(DailyWarSchedule.warDateFor(ist));
}

DailyWarDoc? _warDocFromSnap(
  String dateId,
  DocumentSnapshot<Map<String, dynamic>> snap,
) {
  if (!snap.exists || snap.data() == null) return null;
  return DailyWarDoc.fromMap(dateId, snap.data()!);
}

/// Keys hydrated from Firestore once per app session (no snapshot listeners).
@Riverpod(keepAlive: true)
class DailyWarSessionHydrated extends _$DailyWarSessionHydrated {
  @override
  Set<String> build() => <String>{};

  bool hasKey(String key) => state.contains(key);

  void mark(String key) {
    if (state.contains(key)) return;
    state = {...state, key};
  }
}

/// Public war docs are identical for every user — key by [dateId] only.
String _warHydrateKey(String dateId) => 'war:$dateId';

DateTime _istNow(Ref ref) {
  final offset = ref.read(serverTimeOffsetMsProvider).asData?.value ?? 0;
  return DailyWarSchedule.nowIst(
    DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch + offset,
      isUtc: true,
    ),
  );
}

/// Morning cache with empty `question_uuids` must not be treated as final
/// once the 8:59 publish window opens.
bool _paperAwaitingPublish({
  required DailyWarDoc? doc,
  required String dateId,
  required DateTime ist,
}) {
  if (doc != null && doc.questionUuids.isNotEmpty) return false;
  final todayId = DailyWarSchedule.formatIsoDate(
    DailyWarSchedule.warDateFor(ist),
  );
  if (dateId != todayId) return false;
  return DailyWarSchedule.isOnOrAfterLobby(ist);
}

/// Force-read a public war doc from Firestore and update today's provider
/// when [dateId] is tonight.
Future<DailyWarDoc?> refreshDailyWarDoc(Ref ref, String dateId) async {
  final cache = await ref.read(dailyWarLocalCacheProvider.future);
  final doc = await _fetchWarDoc(
    ref: ref,
    cache: cache,
    dateId: dateId,
    force: true,
  );
  if (dateId == ref.read(dailyWarTodayDateIdProvider)) {
    ref.read(dailyWarTodayDocProvider.notifier).applyFetched(doc);
  }
  return doc;
}

/// Firestore once per session (or [force]); otherwise SharedPreferences cache.
Future<DailyWarDoc?> _fetchWarDoc({
  required Ref ref,
  required DailyWarLocalCache cache,
  required String dateId,
  required bool force,
}) async {
  final key = _warHydrateKey(dateId);
  final hydrated = ref.read(dailyWarSessionHydratedProvider.notifier);
  final cached = cache.getWar(dateId);
  if (!force &&
      hydrated.hasKey(key) &&
      !_paperAwaitingPublish(doc: cached, dateId: dateId, ist: _istNow(ref))) {
    return cached;
  }

  if (!force) {
    final inflight = _warDocInflight[dateId];
    if (inflight != null) return inflight;
  }

  final future = _fetchWarDocFromServer(
    ref: ref,
    cache: cache,
    dateId: dateId,
    key: key,
    cached: cached,
  );
  if (!force) {
    _warDocInflight[dateId] = future;
  }
  try {
    return await future;
  } finally {
    if (!force) _warDocInflight.remove(dateId);
  }
}

Future<DailyWarDoc?> _fetchWarDocFromServer({
  required Ref ref,
  required DailyWarLocalCache cache,
  required String dateId,
  required String key,
  required DailyWarDoc? cached,
}) async {
  final hydrated = ref.read(dailyWarSessionHydratedProvider.notifier);
  try {
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await DailyWarFirestorePaths.warDoc(
        dateId,
      ).get(const GetOptions(source: Source.server));
    } on Object {
      snap = await DailyWarFirestorePaths.warDoc(dateId).get();
    }
    final doc = _warDocFromSnap(dateId, snap);
    if (doc != null) await cache.putWar(doc);
    final awaiting = _paperAwaitingPublish(
      doc: doc ?? cached,
      dateId: dateId,
      ist: _istNow(ref),
    );
    if (!awaiting) hydrated.mark(key);
    return doc ?? cached;
  } on Object catch (e) {
    debugPrint('dailyWar fetch war $dateId failed: $e');
    if (!_paperAwaitingPublish(
      doc: cached,
      dateId: dateId,
      ist: _istNow(ref),
    )) {
      hydrated.mark(key);
    }
    return cached;
  }
}

/// Firestore once per session (or [force]); otherwise local cache / absence.
Future<DailyWarSubmission?> _fetchSubmission({
  required Ref ref,
  required DailyWarLocalCache cache,
  required String uid,
  required String dateId,
  required bool force,
}) async {
  final key = 'sub:$uid:$dateId';
  final hydrated = ref.read(dailyWarSessionHydratedProvider.notifier);
  if (!force && hydrated.hasKey(key)) {
    if (cache.hasKnownAbsence(uid, dateId)) return null;
    return cache.getSubmission(uid, dateId);
  }

  hydrated.mark(key);
  try {
    final snap = await DailyWarFirestorePaths.submissionDoc(
      dateId,
      uid,
    ).get(const GetOptions(source: Source.server));
    if (!snap.exists || snap.data() == null) {
      await cache.putSubmissionAbsent(uid, dateId);
      return null;
    }
    final sub = DailyWarSubmission.fromMap(uid, snap.data()!);
    await cache.putSubmission(uid, sub, dateId);
    return sub;
  } on Object catch (e, st) {
    debugPrint('dailyWar fetch submission $dateId failed: $e');
    debugPrintStack(stackTrace: st);
    return cache.getSubmission(uid, dateId);
  }
}

Future<DailyWarDoc?> _buildWarDoc({
  required Ref ref,
  required String dateId,
  required void Function(DailyWarDoc? doc) setState,
}) async {
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final key = _warHydrateKey(dateId);
  final hydrated = ref.read(dailyWarSessionHydratedProvider.notifier);
  final cached = cache.getWar(dateId);
  final awaiting = _paperAwaitingPublish(
    doc: cached,
    dateId: dateId,
    ist: _istNow(ref),
  );
  if (hydrated.hasKey(key) && !awaiting) return cached;

  if (cached != null) {
    // Instant local paint; one background hydrate. Don't freeze an empty
    // paper after lobby open — questions publish at 20:59.
    if (!awaiting) hydrated.mark(key);
    unawaited(() async {
      final doc = await _fetchWarDoc(
        ref: ref,
        cache: cache,
        dateId: dateId,
        force: true,
      );
      setState(doc);
    }());
    return cached;
  }
  return _fetchWarDoc(ref: ref, cache: cache, dateId: dateId, force: false);
}

/// Today's War public doc — one server read per app open, then local only.
///
/// Gated on the feature flag: `todayHubProvider` watches this from Home for
/// every user, so an ungated read would bill four War documents per session to
/// the ~all of them who cannot see the feature.
@Riverpod(keepAlive: true)
class DailyWarTodayDoc extends _$DailyWarTodayDoc {
  @override
  Future<DailyWarDoc?> build() async {
    if (!await ref.watch(dailyWarRemoteEnabledProvider.future)) return null;
    final dateId = ref.watch(dailyWarTodayDateIdProvider);
    return _buildWarDoc(
      ref: ref,
      dateId: dateId,
      setState: (doc) {
        if (ref.read(dailyWarTodayDateIdProvider) == dateId) {
          state = AsyncValue.data(doc);
        }
      },
    );
  }

  /// Pull-to-refresh / admin regenerate — hits Firestore and updates cache.
  Future<DailyWarDoc?> refresh() async {
    final dateId = ref.read(dailyWarTodayDateIdProvider);
    final cache = await ref.read(dailyWarLocalCacheProvider.future);
    final doc = await _fetchWarDoc(
      ref: ref,
      cache: cache,
      dateId: dateId,
      force: true,
    );
    state = AsyncValue.data(doc);
    return doc;
  }

  void applyFetched(DailyWarDoc? doc) {
    state = AsyncValue.data(doc);
  }
}

/// Signed-in user's submission for today — one server read per app open.
///
/// Gated on the feature flag for the same reason as [DailyWarTodayDoc].
@Riverpod(keepAlive: true)
class DailyWarTodaySubmission extends _$DailyWarTodaySubmission {
  @override
  Future<DailyWarSubmission?> build() async {
    if (!await ref.watch(dailyWarRemoteEnabledProvider.future)) return null;
    final dateId = ref.watch(dailyWarTodayDateIdProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    final cache = await ref.watch(dailyWarLocalCacheProvider.future);
    final key = 'sub:$uid:$dateId';
    final hydrated = ref.read(dailyWarSessionHydratedProvider.notifier);
    if (hydrated.hasKey(key)) {
      if (cache.hasKnownAbsence(uid, dateId)) return null;
      return cache.getSubmission(uid, dateId);
    }
    final cached = cache.getSubmission(uid, dateId);
    if (cached != null || cache.hasKnownAbsence(uid, dateId)) {
      hydrated.mark(key);
      unawaited(() async {
        final sub = await _fetchSubmission(
          ref: ref,
          cache: cache,
          uid: uid,
          dateId: dateId,
          force: true,
        );
        if (ref.read(dailyWarTodayDateIdProvider) == dateId) {
          state = AsyncValue.data(sub);
        }
      }());
      return cache.hasKnownAbsence(uid, dateId) ? null : cached;
    }
    return _fetchSubmission(
      ref: ref,
      cache: cache,
      uid: uid,
      dateId: dateId,
      force: false,
    );
  }

  Future<DailyWarSubmission?> refresh() async {
    final dateId = ref.read(dailyWarTodayDateIdProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      state = const AsyncValue.data(null);
      return null;
    }
    final cache = await ref.read(dailyWarLocalCacheProvider.future);
    final sub = await _fetchSubmission(
      ref: ref,
      cache: cache,
      uid: uid,
      dateId: dateId,
      force: true,
    );
    state = AsyncValue.data(sub);
    return sub;
  }

  /// After a successful Cloud submit — write cache + flip home/lobby CTAs.
  Future<void> applyLocal(DailyWarSubmission sub) async {
    final dateId = ref.read(dailyWarTodayDateIdProvider);
    if (sub.uid.isEmpty || dateId.isEmpty) return;
    final cache = await ref.read(dailyWarLocalCacheProvider.future);
    await cache.putSubmission(sub.uid, sub, dateId);
    ref
        .read(dailyWarSessionHydratedProvider.notifier)
        .mark('sub:${sub.uid}:$dateId');
    state = AsyncValue.data(sub);
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

/// Wall-clock tick so [dailyWarHomeSnapshot] advances lobby / live phases.
/// Offset from RTDB does not change every second.
final dailyWarUiTickProvider = StreamProvider<int>((ref) async* {
  var i = 0;
  while (true) {
    yield i++;
    final ist = DailyWarSchedule.nowIst();
    final warDate = DailyWarSchedule.warDateFor(ist);
    if (DailyWarSchedule.isWarOffDay(warDate)) {
      await Future<void>.delayed(const Duration(minutes: 5));
      continue;
    }
    final lobby = DailyWarSchedule.lobbyOpensAt(warDate);
    final liveEnd = DailyWarSchedule.liveEndsAt(warDate);
    final nearLive =
        !ist.isBefore(lobby.subtract(const Duration(minutes: 5))) &&
        ist.isBefore(liveEnd.add(const Duration(minutes: 5)));
    await Future<void>.delayed(Duration(seconds: nearLive ? 1 : 30));
  }
});

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
      doc != null && doc!.questionsVisible && submission == null;
}

@Riverpod(keepAlive: true)
DailyWarHomeSnapshot dailyWarHomeSnapshot(Ref ref) {
  ref.watch(dailyWarUiTickProvider);
  final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
  final utc = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch + offset,
    isUtc: true,
  );
  final ist = DailyWarSchedule.nowIst(utc);
  // Same source the doc/submission providers are keyed by, so a midnight
  // rollover can't leave yesterday's paper labelled as tonight's.
  final dateId = ref.watch(dailyWarTodayDateIdProvider);
  final fetched = ref.watch(dailyWarTodayDocProvider).asData?.value;
  final doc = fetched?.dateId == dateId ? fetched : null;
  final submission = ref.watch(dailyWarTodaySubmissionProvider).asData?.value;
  final phase = DailyWarPhaseResolver.resolve(
    referenceIst: ist,
    firestoreStatus: doc?.status,
    ranksReady: doc?.ranksReady ?? false,
    questionCount:
        doc?.questionCount ??
        DailyWarSchedule.questionCountForDate(DailyWarSchedule.warDateFor(ist)),
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
  ref.watch(dailyWarUiTickProvider);
  final utc = ref.watch(serverNowUtcProvider);
  final ist = DailyWarSchedule.nowIst(utc);
  // Skip Sunday — previous War night (Sat when today is Mon/Sun).
  final previous = DailyWarSchedule.previousWarDate(
    DailyWarSchedule.warDateFor(ist),
  );
  return DailyWarSchedule.formatIsoDate(previous);
}

/// War night the hub hero should lead with, or null when tonight owns the slot.
///
/// The previous night holds the hero through the working day. From
/// [DailyWarPhaseResolver.hubHeroHandoverHourIst] it steps aside so the screen
/// is about tonight, and the hero only returns once tonight has its own ranks.
@Riverpod(keepAlive: true)
String? dailyWarHubHeroDateId(Ref ref) {
  final snap = ref.watch(dailyWarHomeSnapshotProvider);
  if (snap.phase == DailyWarPhase.resultsReady) return snap.dateId;
  if (snap.istNow.hour >= DailyWarPhaseResolver.hubHeroHandoverHourIst) {
    return null;
  }
  return ref.watch(dailyWarYesterdayDateIdProvider);
}

@Riverpod(keepAlive: true)
class DailyWarYesterdayDoc extends _$DailyWarYesterdayDoc {
  @override
  Future<DailyWarDoc?> build() async {
    if (!await ref.watch(dailyWarRemoteEnabledProvider.future)) return null;
    final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
    return _buildWarDoc(
      ref: ref,
      dateId: dateId,
      setState: (doc) {
        if (ref.read(dailyWarYesterdayDateIdProvider) == dateId) {
          state = AsyncValue.data(doc);
        }
      },
    );
  }

  Future<DailyWarDoc?> refresh() async {
    final dateId = ref.read(dailyWarYesterdayDateIdProvider);
    final cache = await ref.read(dailyWarLocalCacheProvider.future);
    final doc = await _fetchWarDoc(
      ref: ref,
      cache: cache,
      dateId: dateId,
      force: true,
    );
    state = AsyncValue.data(doc);
    return doc;
  }
}

@Riverpod(keepAlive: true)
class DailyWarYesterdaySubmission extends _$DailyWarYesterdaySubmission {
  @override
  Future<DailyWarSubmission?> build() async {
    if (!await ref.watch(dailyWarRemoteEnabledProvider.future)) return null;
    final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    final cache = await ref.watch(dailyWarLocalCacheProvider.future);
    final key = 'sub:$uid:$dateId';
    final hydrated = ref.read(dailyWarSessionHydratedProvider.notifier);
    if (hydrated.hasKey(key)) {
      if (cache.hasKnownAbsence(uid, dateId)) return null;
      return cache.getSubmission(uid, dateId);
    }
    final cached = cache.getSubmission(uid, dateId);
    if (cached != null || cache.hasKnownAbsence(uid, dateId)) {
      hydrated.mark(key);
      unawaited(() async {
        final sub = await _fetchSubmission(
          ref: ref,
          cache: cache,
          uid: uid,
          dateId: dateId,
          force: true,
        );
        if (ref.read(dailyWarYesterdayDateIdProvider) == dateId) {
          state = AsyncValue.data(sub);
        }
      }());
      return cache.hasKnownAbsence(uid, dateId) ? null : cached;
    }
    return _fetchSubmission(
      ref: ref,
      cache: cache,
      uid: uid,
      dateId: dateId,
      force: false,
    );
  }

  Future<DailyWarSubmission?> refresh() async {
    final dateId = ref.read(dailyWarYesterdayDateIdProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      state = const AsyncValue.data(null);
      return null;
    }
    final cache = await ref.read(dailyWarLocalCacheProvider.future);
    final sub = await _fetchSubmission(
      ref: ref,
      cache: cache,
      uid: uid,
      dateId: dateId,
      force: true,
    );
    state = AsyncValue.data(sub);
    return sub;
  }
}

/// Pull-to-refresh on home — re-reads today/yesterday war + submissions from Firestore.
Future<void> refreshDailyWarHome(WidgetRef ref) async {
  await Future.wait([
    ref.read(dailyWarTodayDocProvider.notifier).refresh(),
    ref.read(dailyWarTodaySubmissionProvider.notifier).refresh(),
    ref.read(dailyWarYesterdayDocProvider.notifier).refresh(),
    ref.read(dailyWarYesterdaySubmissionProvider.notifier).refresh(),
  ]);
}

@Riverpod(keepAlive: true)
DailyWarYesterdaySnapshot dailyWarYesterdaySnapshot(Ref ref) {
  final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
  final doc = ref.watch(dailyWarYesterdayDocProvider).asData?.value;
  final submission = ref
      .watch(dailyWarYesterdaySubmissionProvider)
      .asData
      ?.value;
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

/// Lifetime badge tallies — local cache merged with Firestore profile + history.
@Riverpod()
Future<Map<String, int>> dailyWarBadgeTallies(Ref ref) async {
  final cache = await ref.watch(dailyWarLocalCacheProvider.future);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  var tallies = Map<String, int>.from(cache.badgeCounts());

  final bundle = await ref.watch(dailyWarHistoryBundleProvider.future);
  tallies = await cache.mergeBadgeCounts(
    cache.badgeCountsFromSubmissions(bundle.submissions),
  );

  if (uid.isNotEmpty) {
    try {
      final snap = await DailyWarFirestorePaths.profileDoc(uid).get();
      final raw = snap.data()?['badge_counts'];
      if (raw is Map) {
        final remote = <String, int>{};
        for (final e in raw.entries) {
          final n = (e.value as num?)?.toInt() ?? 0;
          if (n > 0) remote['${e.key}'] = n;
        }
        tallies = await cache.mergeBadgeCounts(remote);
      }
    } on Object {
      // Offline — keep local.
    }
  }
  return tallies;
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

  final countsUiOn =
      ref.watch(dailyWarLobbyCountRemoteEnabledProvider).asData?.value ?? true;
  if (!countsUiOn) {
    yield const DailyWarLiveCounts.empty();
    return;
  }

  final snap = ref.watch(dailyWarHomeSnapshotProvider);
  final pollSeconds =
      ref.watch(dailyWarLiveCountPollSecondsRemoteProvider).asData?.value ??
      DailyWarConstants.liveCountPollSeconds;
  final phase = snap.phase;
  final dateId = snap.dateId;
  final shouldPoll =
      phase == DailyWarPhase.lobby ||
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

/// Home card expand/collapse for the current War [dateId].
///
/// Kept alive so ListView dispose/remount on scroll does not reset the UI.
class DailyWarHomeCollapseUi {
  const DailyWarHomeCollapseUi({required this.dateId, required this.collapsed});

  final String dateId;
  final bool collapsed;
}

@Riverpod(keepAlive: true)
class DailyWarHomeCollapse extends _$DailyWarHomeCollapse {
  @override
  DailyWarHomeCollapseUi? build() => null;

  void setCollapsed({required String dateId, required bool collapsed}) {
    state = DailyWarHomeCollapseUi(dateId: dateId, collapsed: collapsed);
  }
}

/// Local War streak — increments on live play, breaks after a missed War night.
final dailyWarStreakCountProvider = Provider<int>((ref) {
  final prefs = ref.watch(prefsServiceProvider).asData?.value;
  if (prefs == null) return 0;
  final utc = ref.watch(serverNowUtcProvider);
  DailyWarStreak.reconcile(prefs: prefs, istNow: DailyWarSchedule.nowIst(utc));
  return prefs.dailyWarStreak;
});
