import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../analytics/question_stats_aggregator.dart';
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

  static const flushMinAge = Duration(hours: 24);
  static const periodicScanInterval = Duration(hours: 1);

  static bool _syncInProgress = false;

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

  /// Aggregates unsynced sessions and writes batched increments to Firestore.
  ///
  /// When [minAge] is set, only sessions completed at least that long ago are
  /// included (used for scheduled auto-flush).
  Future<int> syncUnsyncedSessions({Duration? minAge}) async {
    if (_syncInProgress) return 0;
    _syncInProgress = true;
    try {
      final sessions = await _userDb.sessionsDao.getUnsyncedCompletedSessions(
        minAge: minAge,
      );
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
          final isFirstScored = !record.skipped &&
              !seenScored.contains(record.questionId);
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

        await _commitSessionSync(
          sessionId: session.id,
          logRef: logRef,
          deltas: deltas.values,
        );
        await _userDb.sessionsDao.markSessionSynced(session.id);
        syncedCount++;
      }

      return syncedCount;
    } catch (e, st) {
      debugPrint('QuestionStatsSyncService.syncUnsyncedSessions: $e');
      debugPrintStack(stackTrace: st);
      return 0;
    } finally {
      _syncInProgress = false;
    }
  }

  /// Auto-flush hook: unsynced sessions older than [flushMinAge].
  Future<int> flushStaleSessions() =>
      syncUnsyncedSessions(minAge: flushMinAge);

  /// Immediate best-effort sync of all pending sessions (no age filter).
  Future<int> syncAllPending() => syncUnsyncedSessions();

  /// Increments bookmark counter when a user bookmarks a question.
  Future<void> recordBookmark(String questionId) async {
    try {
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
    try {
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
