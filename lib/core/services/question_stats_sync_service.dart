import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../analytics/question_stats_aggregator.dart';
import 'anonymous_auth_service.dart';
import '../analytics/question_stats_firestore.dart';
import '../database/user_db.dart';
import '../domain/entities/answer_confidence.dart';

/// Batches local per-question attempt records into Firestore `question_stats` docs.
class QuestionStatsSyncService {
  QuestionStatsSyncService({
    required UserDatabase userDb,
    FirebaseFirestore? firestore,
  }) : _userDb = userDb,
       _firestoreOverride = firestore;

  final UserDatabase _userDb;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Retries any sessions that failed to sync (e.g. offline at submit time).
  static const periodicScanInterval = Duration(hours: 1);

  /// Persists immutable attempt snapshots and marks the session unsynced.
  Future<void> persistAttemptsOnSessionComplete(String sessionId) async {
    final existing =
        await _userDb.questionAttemptRecordsDao.getBySessionId(sessionId);
    if (existing.isNotEmpty) {
      await _userDb.sessionsDao.markSessionUnsynced(sessionId);
      return;
    }

    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    if (rows.isEmpty) {
      await _userDb.sessionsDao.markSessionUnsynced(sessionId);
      return;
    }

    final now = DateTime.now();
    final records = rows.map((sq) {
      final skipped = sq.status == 'unattempted' || sq.status == 'timed_out';
      return QuestionAttemptRecordsCompanion.insert(
        id: _uuid.v4(),
        sessionId: sessionId,
        questionId: sq.questionUuid,
        selectedOption: Value(skipped ? null : sq.selectedOption),
        isCorrect: Value(skipped ? null : sq.isCorrect),
        timeTakenSeconds: Value(skipped ? null : sq.timeSpentSecs),
        isSure: Value(
          !skipped && sq.confidence == AnswerConfidence.verySure,
        ),
        skipped: Value(skipped),
        attemptedAt: sq.attemptedAt ?? now,
      );
    }).toList();

    await _userDb.questionAttemptRecordsDao.insertBatch(records);
    await _userDb.sessionsDao.markSessionUnsynced(sessionId);
  }

  /// Persists local attempt rows then uploads aggregates to Firestore.
  Future<void> persistAndSyncSession(String sessionId) async {
    await persistAttemptsOnSessionComplete(sessionId);
    await syncSession(sessionId);
  }

  /// Uploads one completed session to Firestore (no-op if already synced).
  Future<bool> syncSession(String sessionId) async {
    try {
      final signedIn = await AnonymousAuthService.ensureSignedIn();
      if (!signedIn) return false;
      final session = await _userDb.sessionsDao.getSessionById(sessionId);
      if (session == null ||
          session.status != 'completed' ||
          session.synced) {
        return false;
      }
      return (await _syncSessions([session])) > 0;
    } catch (e, st) {
      debugPrint('QuestionStatsSyncService.syncSession: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// Uploads all locally unsynced completed sessions (retry / catch-up).
  Future<int> syncAllPending() => syncUnsyncedSessions();

  /// Aggregates unsynced sessions and writes batched increments to Firestore.
  Future<int> syncUnsyncedSessions() async {
    try {
      final signedIn = await AnonymousAuthService.ensureSignedIn();
      if (!signedIn) return 0;
      final sessions =
          await _userDb.sessionsDao.getUnsyncedCompletedSessions();
      return _syncSessions(sessions);
    } catch (e, st) {
      debugPrint('QuestionStatsSyncService.syncUnsyncedSessions: $e');
      debugPrintStack(stackTrace: st);
      return 0;
    }
  }

  Future<int> _syncSessions(List<Session> sessions) async {
    if (sessions.isEmpty) return 0;

    final priorScored = await _userDb.questionAttemptRecordsDao
        .getQuestionIdsWithPriorScoredAttempts();
    final seenScored = {...priorScored};
    var syncedCount = 0;

    for (final session in sessions) {
      final logRef = _firestore
          .collection(QuestionStatsFirestore.syncLogCollectionName)
          .doc(session.id);
      if ((await logRef.get()).exists) {
        await _userDb.sessionsDao.markSessionSynced(session.id);
        syncedCount++;
        continue;
      }

      var records = await _userDb.questionAttemptRecordsDao.getBySessionId(
        session.id,
      );
      if (records.isEmpty) {
        await persistAttemptsOnSessionComplete(session.id);
        records = await _userDb.questionAttemptRecordsDao.getBySessionId(
          session.id,
        );
      }
      final deltas = <String, QuestionStatsDelta>{};
      for (final record in records) {
        // Rules only accept UUID-shaped `question_stats` doc ids. A handful of
        // bundled questions have malformed ids; one of them in a session would
        // make the whole batch fail PERMISSION_DENIED forever.
        if (!isSyncableQuestionId(record.questionId)) continue;
        final isFirstScored =
            !record.skipped && !seenScored.contains(record.questionId);
        final delta = deltas.putIfAbsent(
          record.questionId,
          () => QuestionStatsDelta(questionId: record.questionId),
        );
        delta.absorbRecord(
          record: record,
          isFirstScoredAttempt: isFirstScored,
        );
        if (!record.skipped) {
          seenScored.add(record.questionId);
        }
      }

      try {
        await _commitSessionSync(
          sessionId: session.id,
          logRef: logRef,
          deltas: deltas.values,
        );
      } on FirebaseException catch (e, st) {
        // Isolate the failure: one rejected session must not block every
        // session queued behind it. It stays unsynced and is retried later.
        debugPrint(
          'QuestionStatsSyncService: session ${session.id} rejected '
          '(${e.code}); continuing',
        );
        debugPrintStack(stackTrace: st);
        continue;
      }
      await _userDb.sessionsDao.markSessionSynced(session.id);
      syncedCount++;
    }

    return syncedCount;
  }

  static final _uuidShape = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Mirrors the `isUuid()` check in `firestore.rules` for `question_stats`.
  @visibleForTesting
  static bool isSyncableQuestionId(String id) => _uuidShape.hasMatch(id);

  /// Increments bookmark counter when a user bookmarks a question.
  Future<void> recordBookmark(String questionId) async {
    if (!isSyncableQuestionId(questionId)) return;
    try {
      await AnonymousAuthService.ensureSignedIn();
      await QuestionStatsFirestore.doc(questionId).set(
        {
          QuestionStatsFirestore.bookmarkedCount: FieldValue.increment(1),
          QuestionStatsFirestore.updatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('QuestionStatsSyncService.recordBookmark: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Increments report counter when a user reports a question error.
  Future<void> recordReport(String questionId) async {
    if (!isSyncableQuestionId(questionId)) return;
    try {
      await AnonymousAuthService.ensureSignedIn();
      await QuestionStatsFirestore.doc(questionId).set(
        {
          QuestionStatsFirestore.reportCount: FieldValue.increment(1),
          QuestionStatsFirestore.updatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('QuestionStatsSyncService.recordReport: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _commitSessionSync({
    required String sessionId,
    required DocumentReference<Map<String, dynamic>> logRef,
    required Iterable<QuestionStatsDelta> deltas,
  }) async {
    final list = deltas.toList();
    if (list.isEmpty) {
      await logRef.set({
        QuestionStatsFirestore.updatedAt: FieldValue.serverTimestamp(),
        'session_id': sessionId,
      });
      return;
    }

    const batchLimit = 499;
    for (var i = 0; i < list.length; i += batchLimit) {
      final chunk = list.skip(i).take(batchLimit).toList();
      final batch = _firestore.batch();
      if (i == 0) {
        batch.set(logRef, {
          QuestionStatsFirestore.updatedAt: FieldValue.serverTimestamp(),
          'session_id': sessionId,
        });
      }
      for (final delta in chunk) {
        final ref = _firestore
            .collection(QuestionStatsFirestore.collectionName)
            .doc(delta.questionId);
        batch.set(ref, delta.toFirestoreIncrements(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
