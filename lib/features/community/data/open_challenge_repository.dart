import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/user_db.dart';
import '../domain/community_legacy_contract.dart';
import '../domain/open_challenge_models.dart';

class OpenChallengeRepository {
  OpenChallengeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'open_challenges';
  static const _indexCollection = 'open_challenges_index';
  static const _indexDoc = 'live';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  /// Home's summary of live challenges — exactly **one** document read no
  /// matter how many challenges exist. Maintained by `onOpenChallengeWritten`.
  ///
  /// Carries no `myScore`: the index has no emails, so callers filter played
  /// challenges with [PrefsService.attemptedOpenChallengeIds] instead.
  Future<List<OpenChallengeListTileModel>> fetchHomeIndex() async {
    final snap = await _firestore
        .collection(_indexCollection)
        .doc(_indexDoc)
        .get(const GetOptions(source: Source.server));
    final raw = snap.data()?['challenges'];
    if (raw is! List) return const [];
    final out = <OpenChallengeListTileModel>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final tile = _indexEntryToTile(Map<String, dynamic>.from(entry));
      if (tile != null) out.add(tile);
    }
    return out;
  }

  /// Full list for the Community tab, with the viewer's own score per row.
  ///
  /// Reads one document per challenge. Home does **not** use this — see
  /// [fetchHomeIndex], which costs a single read.
  Future<List<OpenChallengeListTileModel>> fetchAllSummaries({
    required String? currentUserEmail,
  }) async {
    final me = currentUserEmail?.toLowerCase().trim();
    final snap = await _col.get(const GetOptions(source: Source.server));
    final details = <OpenChallengeDetail>[];
    for (final doc in snap.docs) {
      final detail = OpenChallengeDetail.parse(doc.id, doc.data());
      if (kDebugMode && detail == null) {
        debugPrint(
          '[OpenChallenge:repo] fetchAllSummaries parse=null doc=${doc.id}',
        );
      }
      if (detail != null) details.add(detail);
    }
    details.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    final out = <OpenChallengeListTileModel>[];
    for (final detail in details) {
      if (detail.isExpired) continue;
      final entries = detail.attemptsByEmail.values.toList();
      if (entries.isEmpty) continue;
      var top = entries.first.score;
      for (final e in entries) {
        if (e.score > top) top = e.score;
      }
      int? myScore;
      if (me != null && me.isNotEmpty) {
        myScore = detail.attemptsByEmail[me]?.score;
      }
      final creator = detail.creatorEntry();
      final postedName = creator?.profile.name ?? 'Warrior';
      final postedPhoto =
          creator?.profile.photoUrl ??
          '';
      out.add(
        OpenChallengeListTileModel(
          id: detail.id,
          subject: detail.subject,
          attemptCount: entries.length,
          topScore: top,
          myScore: myScore,
          postedByName: postedName,
          postedByEmail: creator?.profile.email,
          postedByPhotoUrl: postedPhoto,
          postedAt: detail.createdAt ?? creator?.attemptedAt,
          liveUntil: detail.effectiveExpiresAt,
        ),
      );
    }
    return out;
  }

  Future<OpenChallengeDetail?> fetchDetail(String id) async {
    final snap = await _col
        .doc(id)
        .get(const GetOptions(source: Source.server));
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:repo] fetchDetail id=$id exists=${snap.exists} '
        'source=server',
      );
    }
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final parsed = OpenChallengeDetail.parse(id, data);
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:repo] fetchDetail id=$id parsed=${parsed != null} '
        'attemptCount=${parsed?.attemptsByEmail.length ?? 0}',
      );
    }
    return parsed;
  }

  /// Publishes a new challenge after the creator finishes the exam locally.
  Future<String> createChallengeDocument({
    required String creatorEmailKey,
    required List<String> questionUuids,
    required String subject,
    required OpenChallengeProfileSnapshot profile,
    required Map<String, String> attemptsByQuestionUuid,
    required int score,
    String? reviewSessionId,
  }) async {
    final doc = _col.doc();
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 24));
    final creatorPayload = <String, dynamic>{
      'profile': profile.toFirestoreMap(),
      'attempts': attemptsByQuestionUuid,
      'score': score,
      'attempted_at': FieldValue.serverTimestamp(),
    };
    final rs = reviewSessionId?.trim();
    if (rs != null && rs.isNotEmpty) {
      creatorPayload['review_session_id'] = rs;
    }
    // [DocumentReference.set] only accepts String map keys (dots become nested
    // paths). [update] accepts FieldPath — one segment = literal email field.
    await doc.set({
      'questions': questionUuids,
      'subject': subject,
      'created_at': FieldValue.serverTimestamp(),
      'expires_at': Timestamp.fromDate(expiresAt),
    });
    await doc.update(<Object, Object?>{
      FieldPath([creatorEmailKey]): creatorPayload,
    });
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:repo] createChallengeDocument OK id=${doc.id} '
        'creatorKey=$creatorEmailKey score=$score',
      );
    }
    await _touchUserOpenChallengeMeta(email: creatorEmailKey, subject: subject);
    return doc.id;
  }

  /// Adds one attempt; throws if this email already exists on the document.
  Future<void> addAttemptTransaction({
    required String challengeId,
    required String participantEmailKey,
    required OpenChallengeProfileSnapshot profile,
    required Map<String, String> attemptsByQuestionUuid,
    required int score,
    String? reviewSessionId,
  }) async {
    final ref = _col.doc(challengeId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw StateError('Challenge not found');
      }
      final data = snap.data() ?? {};
      if (_firestoreChallengeDataExpired(data)) {
        throw StateError('challenge_expired');
      }
      if (OpenChallengeDetail.documentContainsParticipantAttempt(
        data,
        participantEmailKey,
      )) {
        throw StateError('already_attempted');
      }
      final attemptPayload = <String, dynamic>{
        'profile': profile.toFirestoreMap(),
        'attempts': attemptsByQuestionUuid,
        'score': score,
        'attempted_at': FieldValue.serverTimestamp(),
      };
      final rs = reviewSessionId?.trim();
      if (rs != null && rs.isNotEmpty) {
        attemptPayload['review_session_id'] = rs;
      }
      if (kDebugMode) {
        debugPrint(
          '[OpenChallenge:repo] addAttemptTransaction txn update '
          'challengeId=$challengeId participantKey=$participantEmailKey '
          'score=$score payloadKeys=${attemptPayload.keys.toList()}',
        );
      }
      txn.update(ref, <Object, Object?>{
        FieldPath([participantEmailKey]): attemptPayload,
      });
    });
    await _touchUserOpenChallengeMeta(
      email: participantEmailKey,
      subject: null,
    );
  }

  /// Publishes an open challenge using the exact 10 questions and attempt from
  /// a completed local exam session (no re-test).
  Future<String> createChallengeFromCompletedSession({
    required UserDatabase userDatabase,
    required String sessionId,
    required String creatorEmailKey,
    required OpenChallengeProfileSnapshot profile,
  }) async {
    final session = await userDatabase.sessionsDao.getSessionById(sessionId);
    if (session == null) {
      throw StateError('Session not found');
    }
    if (session.mode != 'exam' || session.questionCount != 10) {
      throw StateError('Only a finished 10-question exam can be posted.');
    }
    final rows = await userDatabase.sessionQuestionsDao
        .getSessionQuestionsOrdered(sessionId);
    if (rows.length != 10) {
      throw StateError('This session does not have 10 questions.');
    }
    final uuids = rows.map((e) => e.questionUuid).toList();
    var correct = 0;
    final attempts = <String, String>{};
    for (final r in rows) {
      if (r.status == 'correct') correct++;
      final o = r.selectedOption?.trim().toLowerCase();
      if (o != null && o.isNotEmpty) {
        attempts[r.questionUuid] = o;
      }
    }
    return createChallengeDocument(
      creatorEmailKey: creatorEmailKey,
      questionUuids: uuids,
      subject: session.subject,
      profile: profile,
      attemptsByQuestionUuid: attempts,
      score: correct,
      reviewSessionId: sessionId,
    );
  }

  Future<void> _touchUserOpenChallengeMeta({
    required String email,
    required String? subject,
  }) async {
    final payload = <String, dynamic>{
      CommunityLegacyContract.lastOnlineTime:
          DateTime.now().millisecondsSinceEpoch,
      CommunityLegacyContract.lastOpenChallengeAt:
          DateTime.now().millisecondsSinceEpoch,
    };
    if (subject != null && subject.isNotEmpty) {
      payload[CommunityLegacyContract.lastOpenChallengeSubject] = subject;
    }
    await _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .doc(email.toLowerCase())
        .set(payload, SetOptions(merge: true));
  }
}

DateTime? _msToDate(Object? value) {
  final ms = (value as num?)?.toInt();
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

/// Parses one entry of `open_challenges_index/live`. Mirrors the shape written
/// by `openChallengeIndexEntry` in `functions/index.js`.
OpenChallengeListTileModel? _indexEntryToTile(Map<String, dynamic> m) {
  final id = (m['id'] as String?)?.trim();
  if (id == null || id.isEmpty) return null;
  return OpenChallengeListTileModel(
    id: id,
    subject: (m['subject'] as String?) ?? '',
    attemptCount: (m['attempt_count'] as num?)?.toInt() ?? 0,
    topScore: (m['top_score'] as num?)?.toInt() ?? 0,
    postedByName: (m['posted_by_name'] as String?) ?? '',
    postedByPhotoUrl: (m['posted_by_photo_url'] as String?) ?? '',
    postedAt: _msToDate(m['posted_at_ms']),
    liveUntil: _msToDate(m['live_until_ms']),
  );
}

bool _firestoreChallengeDataExpired(Map<String, dynamic> data) {
  final exp = data['expires_at'];
  final created = data['created_at'];
  DateTime? end;
  if (exp is Timestamp) {
    end = exp.toDate();
  } else if (created is Timestamp) {
    end = created.toDate().toUtc().add(const Duration(hours: 24));
  }
  if (end == null) return false;
  return DateTime.now().toUtc().isAfter(end.toUtc());
}

/// Picks 10 random question UUIDs for a catalog subject (SQLite subject string).
/// [subject] `misc` uses the same mixed bank as battles: any subject, unseen-first.
Future<List<String>> pickTenRandomQuestionUuidsForSubject({
  required UserDatabase userDatabase,
  required String subject,
}) async {
  final attempted = await userDatabase.sessionQuestionsDao
      .getAllAttemptedQuestionUuids();
  final picked = subject == 'misc'
      ? await userDatabase.questionsDao.getUnseenFirstRandomMixed(
          limit: 10,
          attemptedQuestionUuids: attempted,
        )
      : await userDatabase.questionsDao.getUnseenFirstBySubject(
          subject: subject,
          limit: 10,
          attemptedQuestionUuids: attempted,
        );
  if (picked.length < 10) {
    throw StateError(
      subject == 'misc'
          ? 'Not enough questions in your bank for a mixed challenge.'
          : 'Not enough questions in this subject.',
    );
  }
  return picked.map((q) => q.uuid).toList();
}

OpenChallengeProfileSnapshot profileFromFirebaseUser({
  required String emailLower,
  required String displayName,
  required String? photoUrl,
  String? telegram,
  String? instagram,
  String? status,
}) {
  return OpenChallengeProfileSnapshot(
    email: emailLower,
    name: displayName.trim().isEmpty ? 'UPSC Warrior' : displayName.trim(),
    photoUrl: AppConstants.customProfilePhotoUrl(photoUrl),
    telegram: telegram,
    instagram: instagram,
    status: status,
  );
}
