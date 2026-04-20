import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upsc_wars/core/deep_link/share_link_kind.dart';

/// Firestore collection for shared test links (read: web + app resolver).
abstract final class SharedSessionFirestore {
  static const collectionName = 'session';

  static DocumentReference<Map<String, dynamic>> doc(String shareId) {
    return FirebaseFirestore.instance.collection(collectionName).doc(shareId);
  }
}

/// Payload stored at `session/{shareId}`.
class SharedSessionDocument {
  const SharedSessionDocument({
    required this.kind,
    required this.subject,
    this.topic,
    this.sharedBy,
    required this.uuids,
  });

  final ShareLinkKind kind;
  final String subject;
  final String? topic;
  final String? sharedBy;

  /// Ordered list of question JSON maps (`uuid` + full display fields).
  final List<Map<String, dynamic>> uuids;

  List<String> get orderedQuestionUuids =>
      uuids.map((m) => m['uuid'] as String).toList();
}

class SharedLeaderboardEntry {
  const SharedLeaderboardEntry({
    required this.name,
    required this.score,
    required this.attemptedAtMs,
  });

  final String name;
  final double score;
  final int attemptedAtMs;
}

class SharedSessionFirestoreRepository {
  SharedSessionFirestoreRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _leaderboardCollection(String shareId) {
    return _db
        .collection(SharedSessionFirestore.collectionName)
        .doc(shareId)
        .collection('leaderboard');
  }

  Future<void> uploadSession({
    required String shareId,
    required ShareLinkKind kind,
    required String subject,
    String? topic,
    required List<Map<String, dynamic>> questionMaps,
  }) async {
    // Firestore rules expect schemaVersion as a number; use explicit int.
    final safeSubject = subject.trim().isEmpty ? 'Misc' : subject.trim();
    await _db.collection(SharedSessionFirestore.collectionName).doc(shareId).set({
      'kind': kind.pathSegment,
      'subject': safeSubject,
      if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
      'uuids': questionMaps,
      'createdAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    });
  }

  Future<SharedSessionDocument> fetch(String shareId) async {
    final snap =
        await _db.collection(SharedSessionFirestore.collectionName).doc(shareId).get();
    if (!snap.exists) {
      throw StateError('Shared session not found.');
    }
    final d = snap.data()!;
    final kindRaw = d['kind'] as String?;
    final kind = kindRaw != null ? ShareLinkKind.parse(kindRaw) : null;
    if (kind == null) {
      throw StateError('Invalid shared session data.');
    }
    final raw = d['uuids'];
    if (raw is! List || raw.isEmpty) {
      throw StateError('Shared session has no questions.');
    }
    final uuids = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        uuids.add(e);
      } else if (e is Map) {
        uuids.add(Map<String, dynamic>.from(e));
      }
    }
    if (uuids.isEmpty) {
      throw StateError('Shared session has no questions.');
    }
    for (final m in uuids) {
      final u = m['uuid'];
      if (u is! String || u.isEmpty) {
        throw StateError('Invalid question entry in shared session.');
      }
    }
    final subject = (d['subject'] as String?)?.trim();
    if (subject == null || subject.isEmpty) {
      throw StateError('Shared session missing subject.');
    }
    final topicRaw = d['topic'] as String?;
    final topic = topicRaw?.trim();
    final sharedByRaw = (d['Shared by'] ?? d['sharedBy']) as String?;
    final sharedBy = sharedByRaw?.trim();
    return SharedSessionDocument(
      kind: kind,
      subject: subject,
      topic: (topic != null && topic.isNotEmpty) ? topic : null,
      sharedBy: (sharedBy != null && sharedBy.isNotEmpty) ? sharedBy : null,
      uuids: uuids,
    );
  }

  Future<void> appendLeaderboardAttempt({
    required String shareId,
    required String name,
    required double score,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final clamped = score.clamp(0.0, 100.0);
    await _leaderboardCollection(shareId).add({
      'name': trimmed,
      'score': clamped,
      'attemptedAt': FieldValue.serverTimestamp(),
      'attemptedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<SharedLeaderboardEntry>> fetchTopLeaderboard({
    required String shareId,
    int limit = 5,
  }) async {
    final safeLimit = limit < 1 ? 1 : (limit > 20 ? 20 : limit);
    final snap = await _leaderboardCollection(shareId)
        .orderBy('score', descending: true)
        .limit(50)
        .get();

    final out = <SharedLeaderboardEntry>[];
    for (final d in snap.docs) {
      final m = d.data();
      final name = (m['name'] as String?)?.trim();
      final score = (m['score'] as num?)?.toDouble();
      final attemptedAtMs = (m['attemptedAtMs'] as num?)?.toInt();
      if (name == null || name.isEmpty || score == null || attemptedAtMs == null) {
        continue;
      }
      out.add(
        SharedLeaderboardEntry(
          name: name,
          score: score,
          attemptedAtMs: attemptedAtMs,
        ),
      );
    }

    out.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return b.attemptedAtMs.compareTo(a.attemptedAtMs);
    });
    if (out.length <= safeLimit) return out;
    return out.sublist(0, safeLimit);
  }
}
