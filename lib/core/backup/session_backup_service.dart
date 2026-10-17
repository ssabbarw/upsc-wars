import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../auth/auth_session.dart';
import '../database/user_db.dart';
import 'backup_snapshot.dart';
import 'backup_snapshot_isolate_stub.dart'
    if (dart.library.io) 'backup_snapshot_isolate_io.dart';
import 'session_backup_codec.dart';

/// Where a restore currently is — drives the home "Restoring your data" card.
enum RestorePhase { idle, restoring, done, failed }

/// Snapshot of restore progress.
@immutable
class RestoreProgress {
  const RestoreProgress({
    this.phase = RestorePhase.idle,
    this.total = 0,
    this.done = 0,
    this.restored = 0,
    this.message,
  });

  final RestorePhase phase;

  /// Attempts found in the cloud backup.
  final int total;

  /// Attempts processed so far (restored or skipped as already local).
  final int done;

  /// Attempts actually added to this device.
  final int restored;

  /// Short user-facing hint, e.g. "Fetching current affairs…".
  final String? message;

  double? get fraction => total <= 0 ? null : (done / total).clamp(0.0, 1.0);

  RestoreProgress copyWith({
    RestorePhase? phase,
    int? total,
    int? done,
    int? restored,
    String? message,
  }) => RestoreProgress(
    phase: phase ?? this.phase,
    total: total ?? this.total,
    done: done ?? this.done,
    restored: restored ?? this.restored,
    message: message ?? this.message,
  );
}

/// Backs up every completed test (answers, timing, confidence) to Firestore as
/// **one document per attempt**, and restores them after a reinstall.
///
/// Cost model: one write per submitted test; one read per attempt on restore
/// (done once per account per install).
///
/// Backups are keyed by Firebase uid and only for real accounts. Anonymous
/// users keep `backed_up_at` null; [runBackfillOnce] uploads their history the
/// moment they sign in (linking keeps the uid, so the backup stays theirs).
class SessionBackupService {
  SessionBackupService({
    required UserDatabase userDb,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = userDb,
       _firestoreOverride = firestore,
       _authOverride = auth;

  final UserDatabase _db;
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const _uuid = Uuid();

  /// Set once the one-time pre-update history upload has fully succeeded.
  static const backfillDonePrefKey = 'backup_backfill_done_v1';

  /// Sessions read + encoded per isolate run (bounds memory).
  static const _backfillBatch = 100;
  static const _backfillMaxBatches = 1000;
  static bool _backfillRunning = false;

  /// Sessions per `WriteBatch` (each doc ≈ 10 KB, so ~200 KB per commit).
  static const _writeChunk = 20;

  /// Docs fetched per restore page.
  static const _restorePageSize = 40;

  /// Offline commits never resolve; the SDK still queues the write, we simply
  /// stop waiting and leave the session pending for the next retry.
  static const _commitTimeout = Duration(seconds: 25);

  /// Serialises backups so submit + startup retry never upload the same
  /// session twice concurrently.
  static Future<void> _queueTail = Future.value();

  static Future<T> _enqueue<T>(Future<T> Function() job) {
    final next = _queueTail.then((_) => job());
    _queueTail = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  String? get _uid {
    final user = _auth.currentUser;
    return AuthSession.isAccountSignedIn(user) ? user!.uid : null;
  }

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _firestore
          .collection(SessionBackupFormat.collectionName)
          .doc(uid)
          .collection(SessionBackupFormat.sessionsSubcollection);

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  /// Backs up one just-submitted session inline. Safe to call fire-and-forget.
  ///
  /// This is the steady-state path: one write per submitted test.
  Future<void> backupSession(String sessionId) async {
    try {
      final session = await _db.sessionsDao.getSessionById(sessionId);
      if (session == null || session.status != 'completed') return;
      await _enqueue(() => _uploadSessions([session]));
    } catch (e, st) {
      debugPrint('SessionBackupService.backupSession: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Re-sends sessions whose inline upload failed (offline at submit, signed
  /// out at the time). A purely local query: when nothing is pending it costs
  /// no Firestore operations. Does nothing until the one-time backfill has
  /// finished, so the backfill (not this) owns pre-update history.
  Future<int> retryPending() async {
    try {
      if (_uid == null) return 0;
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(backfillDonePrefKey) ?? false)) return 0;
      return await _enqueue(() async {
        final pending = await _db.sessionsDao.getSessionsPendingBackup();
        if (pending.isEmpty) return 0;
        return _uploadSessions(pending);
      });
    } catch (e, st) {
      debugPrint('SessionBackupService.retryPending: $e');
      debugPrintStack(stackTrace: st);
      return 0;
    }
  }

  /// One-time upload of everything on this device that predates backup (old
  /// users updating the app) plus anything completed while anonymous.
  ///
  /// Reading and encoding the history runs on a **background isolate**; only
  /// the Firestore commits happen on the main isolate. Once it completes
  /// without error a pref flag is set and it never runs again — from then on
  /// each test is uploaded inline at submit. Any failure (offline, denied)
  /// leaves the flag unset so the next launch resumes where it stopped:
  /// finished sessions are already marked `backed_up_at`.
  ///
  /// Returns true when the backfill is complete (now or previously).
  Future<bool> runBackfillOnce() async {
    if (_backfillRunning) return false;
    _backfillRunning = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(backfillDonePrefKey) ?? false) return true;
      final uid = _uid;
      if (uid == null) return false; // anonymous: wait for sign-in

      final path = await userDbFilePath();
      for (var i = 0; i < _backfillMaxBatches; i++) {
        final snapshot = path != null
            ? await buildPendingSnapshotInBackground(
                dbPath: path,
                limit: _backfillBatch,
              )
            : await buildPendingBackupSnapshot(_db, limit: _backfillBatch);
        if (snapshot.isEmpty) {
          await prefs.setBool(backfillDonePrefKey, true);
          return true;
        }
        final ok = await _enqueue(() => _commitSnapshot(uid, snapshot));
        if (!ok) return false;
      }
      return false;
    } catch (e, st) {
      debugPrint('SessionBackupService.runBackfillOnce: $e');
      debugPrintStack(stackTrace: st);
      return false;
    } finally {
      _backfillRunning = false;
    }
  }

  Future<int> _uploadSessions(List<Session> sessions) async {
    final uid = _uid;
    if (uid == null || sessions.isEmpty) return 0;
    final payloads = <Map<String, dynamic>>[];
    final skipped = <String>[];
    for (final s in sessions) {
      final payload = await buildBackupPayload(_db, s);
      if (payload == null) {
        skipped.add(s.id);
      } else {
        payloads.add(payload);
      }
    }
    final ok = await _commitSnapshot(
      uid,
      BackupSnapshot(payloads: payloads, skippedIds: skipped),
    );
    return ok ? payloads.length : 0;
  }

  /// Writes [snapshot] to Firestore in small batches and marks each session
  /// backed up once its batch is acknowledged. Returns false if it had to stop
  /// early (offline timeout); sessions not yet acknowledged stay pending.
  Future<bool> _commitSnapshot(String uid, BackupSnapshot snapshot) async {
    final ref = _sessionsRef(uid);
    if (snapshot.skippedIds.isNotEmpty) {
      await _db.sessionsDao.markSessionsBackedUp(
        snapshot.skippedIds,
        DateTime.now(),
      );
    }
    final payloads = snapshot.payloads;
    for (var i = 0; i < payloads.length; i += _writeChunk) {
      final chunk = payloads.skip(i).take(_writeChunk).toList();
      final batch = _firestore.batch();
      for (final payload in chunk) {
        payload[SessionBackupFormat.backedUpAt] = FieldValue.serverTimestamp();
        batch.set(ref.doc(payload[SessionBackupFormat.sid] as String), payload);
      }
      try {
        await batch.commit().timeout(_commitTimeout);
      } on TimeoutException {
        // Likely offline: the SDK keeps the write queued; the sessions stay
        // pending so a later run confirms them.
        return false;
      }
      await _db.sessionsDao.markSessionsBackedUp([
        for (final payload in chunk) payload[SessionBackupFormat.sid] as String,
      ], DateTime.now());
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Whether this account has any backed-up attempts (one cheap aggregate read).
  Future<int> remoteCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    final snap = await _sessionsRef(uid).count().get();
    return snap.count ?? 0;
  }

  /// Pulls the account's backed-up attempts onto this device.
  ///
  /// Idempotent: sessions already present locally are skipped, and restored
  /// ones are marked synced + backed-up so they are neither re-aggregated into
  /// global question stats nor re-uploaded. Throws on network/permission
  /// errors so the caller can offer a retry.
  ///
  /// [ensureCaDate] fetches a Daily CA day into the local bank; used for
  /// current-affairs questions that a fresh install does not have yet.
  Future<int> restore({
    void Function(RestoreProgress progress)? onProgress,
    Future<void> Function(String isoDate)? ensureCaDate,
  }) async {
    final uid = _uid;
    if (uid == null) return 0;

    final total = await remoteCount();
    var progress = RestoreProgress(
      phase: RestorePhase.restoring,
      total: total,
    );
    onProgress?.call(progress);
    if (total == 0) return 0;

    final ref = _sessionsRef(uid);
    final triedCaDates = <String>{};
    var restored = 0;
    var done = 0;
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      var query = ref
          .orderBy(SessionBackupFormat.completedAtMs)
          .limit(_restorePageSize);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final page = await query.get();
      if (page.docs.isEmpty) break;
      cursor = page.docs.last;

      final decoded = <RestoredSession>[];
      for (final doc in page.docs) {
        final r = SessionBackupCodec.decode(doc.data());
        if (r != null) decoded.add(r);
      }

      final existing = await _db.sessionsDao.existingSessionIds([
        for (final r in decoded) r.id,
      ]);
      final fresh = decoded.where((r) => !existing.contains(r.id)).toList();

      if (fresh.isNotEmpty) {
        if (ensureCaDate != null) {
          progress = progress.copyWith(
            message: 'Fetching current affairs…',
          );
          onProgress?.call(progress);
          await _cacheMissingCaQuestions(fresh, triedCaDates, ensureCaDate);
        }
        await _insertRestored(fresh);
        restored += fresh.length;
      }

      done += page.docs.length;
      progress = progress.copyWith(
        done: done,
        restored: restored,
        message: 'Restoring your tests…',
      );
      onProgress?.call(progress);

      if (page.docs.length < _restorePageSize) break;
    }

    return restored;
  }

  Future<void> _cacheMissingCaQuestions(
    List<RestoredSession> sessions,
    Set<String> triedDates,
    Future<void> Function(String isoDate) ensureCaDate,
  ) async {
    final wantedByDate = <String, Set<String>>{};
    for (final s in sessions) {
      s.caDatesByUuid.forEach((uuid, date) {
        wantedByDate.putIfAbsent(date, () => {}).add(uuid);
      });
    }
    if (wantedByDate.isEmpty) return;

    final allUuids = [for (final set in wantedByDate.values) ...set];
    final present = {
      for (final q in await _db.questionsDao.getByUuidsInOrder(allUuids))
        q.uuid,
    };
    final datesToFetch = <String>[
      for (final e in wantedByDate.entries)
        if (!triedDates.contains(e.key) &&
            e.value.any((u) => !present.contains(u)))
          e.key,
    ]..sort();

    const parallel = 4;
    for (var i = 0; i < datesToFetch.length; i += parallel) {
      final batch = datesToFetch.skip(i).take(parallel).toList();
      triedDates.addAll(batch);
      await Future.wait(
        batch.map((d) async {
          try {
            await ensureCaDate(d);
          } catch (e) {
            // A CA day that is gone from the archive just stays missing.
            debugPrint('SessionBackupService: CA $d not restored: $e');
          }
        }),
      );
    }
  }

  @visibleForTesting
  Future<void> applyRestoredForTest(List<RestoredSession> sessions) =>
      _insertRestored(sessions);

  Future<void> _insertRestored(List<RestoredSession> sessions) async {
    await _db.transaction(() async {
      for (final r in sessions) {
        await _db.sessionsDao.insertSession(r.session);
        await _db.sessionQuestionsDao.insertBatch(r.attempts);
      }
    });
    // Sessions arrive oldest-first, so replaying them in order reproduces the
    // queue's real history.
    for (final r in sessions) {
      await _rebuildTopicStats(r);
      await _replayRevisionQueue(r);
    }
  }

  /// Rebuilds `revision_queue` from answer history by replaying the same rules
  /// the live app applies:
  ///  * a **wrong** answer in a submitted session (re)queues the question and
  ///    bumps its "incorrect in revision" count (`submitSession`);
  ///  * a **correct** answer inside a revision session, while the question is
  ///    queued, bumps its "correct" count and graduates it
  ///    (`updateRevisionQueueProgress`).
  ///
  /// Not recoverable from attempts: questions queued by hand ("Add to
  /// revision") or via bookmark and never answered wrong.
  Future<void> _replayRevisionQueue(RestoredSession r) async {
    final isRevision =
        r.session.subject.value == 'revision' ||
        r.session.subject.value == 'revision_quick';
    final completedAt = r.session.completedAt.value ?? DateTime.now();
    final dao = _db.revisionQueueDao;

    if (isRevision) {
      // Correct answers happen mid-session, before the submit-time re-queue.
      final correct = r.attempts
          .where((a) => a.status.value == 'correct')
          .toList()
        ..sort(
          (a, b) => (a.attemptedAt.value ?? completedAt).compareTo(
            b.attemptedAt.value ?? completedAt,
          ),
        );
      for (final a in correct) {
        final uuid = a.questionUuid.value;
        final row = await dao.getRevisionQueueItemByQuestionUuid(uuid);
        if (row == null || row.hasGraduatedFromQueue) continue;
        await dao.updateCounts(questionUuid: uuid, answeredCorrectly: true);
        await dao.graduate(uuid, a.attemptedAt.value ?? completedAt);
      }
    }

    for (final a in r.attempts.where((a) => a.status.value == 'wrong')) {
      final uuid = a.questionUuid.value;
      await dao.add(
        id: _uuid.v4(),
        questionUuid: uuid,
        dateAddedToQueue: completedAt,
      );
      await dao.updateCounts(questionUuid: uuid, answeredCorrectly: false);
    }
  }

  /// Mirrors `TestEngineRepositoryImpl._updateTopicStatsForSession` so
  /// per-topic accuracy survives a reinstall.
  Future<void> _rebuildTopicStats(RestoredSession r) async {
    final scored = r.attempts
        .where(
          (a) => a.status.value == 'correct' || a.status.value == 'wrong',
        )
        .toList();
    if (scored.isEmpty) return;

    final questions = await _db.questionsDao.getByUuidsInOrder([
      for (final a in scored) a.questionUuid.value,
    ]);
    final byUuid = {for (final q in questions) q.uuid: q};
    final agg =
        <String, ({String subject, String topic, int n, int ok, int bad, int t})>{};
    for (final a in scored) {
      final q = byUuid[a.questionUuid.value];
      if (q == null) continue;
      final key = '${q.subject}||${q.topic}';
      final prev = agg[key];
      final correct = a.status.value == 'correct';
      agg[key] = (
        subject: q.subject,
        topic: q.topic,
        n: (prev?.n ?? 0) + 1,
        ok: (prev?.ok ?? 0) + (correct ? 1 : 0),
        bad: (prev?.bad ?? 0) + (correct ? 0 : 1),
        t: (prev?.t ?? 0) + (a.timeSpentSecs.value ?? 0),
      );
    }

    final at = r.session.completedAt.value ?? DateTime.now();
    for (final e in agg.values) {
      await _db.userTopicStatsDao.upsertAfterSessionCompletion(
        subject: e.subject,
        topic: e.topic,
        attemptedToAdd: e.n,
        correctToAdd: e.ok,
        wrongToAdd: e.bad,
        timeSpentSecsSum: e.t,
        attemptedAt: at,
      );
    }
  }
}
