import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/user_db.dart';
import '../domain/open_challenge_models.dart';
import '../domain/qotd_models.dart';
import '../domain/qotd_reactions.dart';

class QotdRepository {
  QotdRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'qotd_posts';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  Future<String> createPost({
    required String questionUuid,
    required String comment,
    required String correctOption,
    required OpenChallengeProfileSnapshot author,
  }) async {
    final doc = _col.doc();
    final co = correctOption.toLowerCase().trim();
    if (!{'a', 'b', 'c', 'd'}.contains(co)) {
      throw ArgumentError('correct_option');
    }
    await doc.set({
      'question_uuid': questionUuid.trim(),
      'comment': comment.trim(),
      'correct_option': co,
      'author_email': author.email.toLowerCase().trim(),
      'author_name': author.name,
      'author_photo_url': author.photoUrl,
      'created_at': FieldValue.serverTimestamp(),
      'correct_count': 0,
      'wrong_count': 0,
      'reaction_counts': <String, int>{},
      'attempts': <String, dynamic>{},
      'reactions': <String, dynamic>{},
    });
    return doc.id;
  }

  Future<
      ({
        List<QotdPost> posts,
        DocumentSnapshot<Map<String, dynamic>>? last,
      })> fetchPage({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q =
        _col.orderBy('created_at', descending: true).limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    if (snap.docs.isEmpty) {
      return (posts: const <QotdPost>[], last: null);
    }
    final posts = <QotdPost>[];
    for (final d in snap.docs) {
      final p = QotdPost.parse(d.id, d.data());
      if (p != null) posts.add(p);
    }
    return (posts: posts, last: snap.docs.last);
  }

  Future<QotdPost?> fetchPost(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return QotdPost.parse(id, snap.data() ?? {});
  }

  Future<String?> userAttemptPick({
    required String postId,
    required String uid,
  }) async {
    final snap = await _col.doc(postId).get();
    if (!snap.exists) return null;
    final attempts = snap.data()?['attempts'];
    if (attempts is! Map) return null;
    final att = attempts[uid];
    if (att is! Map) return null;
    return (att['picked'] as String?)?.toLowerCase().trim();
  }

  Future<String?> reactionIdForUser({
    required String postId,
    required String uid,
  }) async {
    final snap = await _col.doc(postId).get();
    if (!snap.exists) return null;
    final reactions = snap.data()?['reactions'];
    if (reactions is! Map) return null;
    final r = reactions[uid];
    if (r is! Map) return null;
    final id = (r['reaction_id'] as String?)?.trim();
    if (id != null && id.isNotEmpty && qotdReactionIds.contains(id)) {
      return id;
    }
    return null;
  }

  Future<void> setUserReaction({
    required String postId,
    required String uid,
    required String reactionId,
  }) async {
    if (!qotdReactionIds.contains(reactionId)) {
      throw ArgumentError('reactionId');
    }
    final postRef = _col.doc(postId);

    await _firestore.runTransaction((txn) async {
      final postSnap = await txn.get(postRef);
      if (!postSnap.exists) throw StateError('post_missing');
      final data = postSnap.data() ?? {};

      String? prevKey;
      final reactionsRaw = data['reactions'];
      if (reactionsRaw is Map && reactionsRaw[uid] is Map) {
        final rm = Map<String, dynamic>.from(reactionsRaw[uid] as Map);
        final raw = rm['reaction_id'];
        final pk = (raw is String ? raw : raw?.toString())?.trim();
        if (pk != null && pk.isNotEmpty && qotdReactionIds.contains(pk)) {
          prevKey = pk;
        }
      }

      if (prevKey != null) {
        if (prevKey == reactionId) return;
        throw StateError('qotd_reaction_immutable');
      }

      final tallies = <String, int>{};
      final rawMap = data['reaction_counts'];
      if (rawMap is Map) {
        for (final e in rawMap.entries) {
          final k = e.key.toString();
          if (!qotdReactionIds.contains(k)) continue;
          final v = e.value;
          final n = v is int ? v : int.tryParse(v.toString()) ?? 0;
          if (n > 0) tallies[k] = n;
        }
      }

      tallies[reactionId] = (tallies[reactionId] ?? 0) + 1;

      txn.update(postRef, {
        'reactions.$uid': {
          'reaction_id': reactionId,
          'updated_at': FieldValue.serverTimestamp(),
        },
        'reaction_counts': tallies,
      });
    });
  }

  Future<Map<String, int>> reactionCounts(String postId) async {
    final snap = await _col.doc(postId).get();
    if (!snap.exists) return {};
    final raw = snap.data()?['reaction_counts'];
    if (raw is! Map) return {};
    final out = <String, int>{};
    for (final e in raw.entries) {
      final k = e.key.toString();
      if (!qotdReactionIds.contains(k)) continue;
      final v = e.value;
      final n = v is int ? v : int.tryParse(v.toString()) ?? 0;
      if (n > 0) out[k] = n;
    }
    return out;
  }

  Stream<List<QotdAttemptEntry>> watchAttempts(String postId) {
    return _col.doc(postId).snapshots().map((snap) {
      if (!snap.exists) return const <QotdAttemptEntry>[];
      return _attemptsListFromData(snap.data());
    });
  }

  List<QotdAttemptEntry> _attemptsListFromData(Map<String, dynamic>? data) {
    final raw = data?['attempts'];
    if (raw is! Map) return const [];
    final list = <QotdAttemptEntry>[];
    for (final e in raw.entries) {
      final uid = e.key.toString();
      if (uid.isEmpty) continue;
      final v = e.value;
      if (v is! Map) continue;
      final m = Map<String, dynamic>.from(v);
      final ts = m['attempted_at'];
      DateTime at;
      if (ts is Timestamp) {
        at = ts.toDate();
      } else {
        at = DateTime.fromMillisecondsSinceEpoch(0);
      }
      final pick = (m['picked'] as String?)?.trim().toLowerCase() ?? '';
      final ok = m['correct'] == true;
      final ae = (m['author_email'] as String?)?.toLowerCase().trim();
      final an = (m['author_name'] as String?)?.trim();
      final ap = (m['author_photo_url'] as String?)?.trim();
      list.add(
        QotdAttemptEntry(
          uid: uid,
          pickedOption: pick.isEmpty ? '?' : pick.toUpperCase(),
          isCorrect: ok,
          attemptedAt: at,
          authorEmail: (ae != null && ae.isNotEmpty) ? ae : null,
          authorName: (an != null && an.isNotEmpty) ? an : null,
          authorPhotoUrl: (ap != null && ap.isNotEmpty) ? ap : null,
        ),
      );
    }
    list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    return list;
  }

  Future<
      ({
        bool isCorrect,
        bool alreadyAttempted,
        int correctCount,
        int wrongCount,
      })> submitAttempt({
    required String postId,
    required String uid,
    required String pickedOption,
    required String correctOption,
    OpenChallengeProfileSnapshot? author,
  }) async {
    final pick = pickedOption.toLowerCase().trim();
    if (!{'a', 'b', 'c', 'd'}.contains(pick)) {
      throw ArgumentError('picked');
    }
    final correct = correctOption.toLowerCase().trim();
    final isCorrect = pick == correct;

    final postRef = _col.doc(postId);

    return _firestore.runTransaction((txn) async {
      final postSnap = await txn.get(postRef);
      if (!postSnap.exists) throw StateError('post_missing');
      final d = postSnap.data() ?? {};
      final baseCorrect = (d['correct_count'] as num?)?.toInt() ?? 0;
      final baseWrong = (d['wrong_count'] as num?)?.toInt() ?? 0;

      final attemptsRaw = d['attempts'];
      if (attemptsRaw is Map && attemptsRaw[uid] is Map) {
        final prev = Map<String, dynamic>.from(attemptsRaw[uid] as Map);
        final prevCorrect = prev['correct'] == true;
        return (
          isCorrect: prevCorrect,
          alreadyAttempted: true,
          correctCount: baseCorrect,
          wrongCount: baseWrong,
        );
      }

      final attData = <String, dynamic>{
        'picked': pick,
        'correct': isCorrect,
        'attempted_at': FieldValue.serverTimestamp(),
      };
      final em = author?.email.toLowerCase().trim() ?? '';
      if (em.isNotEmpty) {
        attData['author_email'] = em;
        attData['author_name'] = author!.name;
        attData['author_photo_url'] = author.photoUrl;
      }

      txn.update(postRef, {
        'attempts.$uid': attData,
        if (isCorrect) 'correct_count': FieldValue.increment(1),
        if (!isCorrect) 'wrong_count': FieldValue.increment(1),
      });
      return (
        isCorrect: isCorrect,
        alreadyAttempted: false,
        correctCount: baseCorrect + (isCorrect ? 1 : 0),
        wrongCount: baseWrong + (isCorrect ? 0 : 1),
      );
    });
  }
}

/// Picks one UUID for the QOTD post flow (prefer unseen; falls back to any).
Future<String?> pickRandomQuestionUuidForQotd({
  required UserDatabase db,
  required String subject,
}) async {
  final attempted = await db.sessionQuestionsDao.getAllAttemptedQuestionUuids();
  final unseen = await db.questionsDao.getUnseenFirstBySubject(
    subject: subject,
    limit: 1,
    attemptedQuestionUuids: attempted,
  );
  if (unseen.isNotEmpty) return unseen.first.uuid;
  final pool = await db.questionsDao.getBySubject(subject);
  if (pool.isEmpty) return null;
  return pool[Random().nextInt(pool.length)].uuid;
}
