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
    required this.uuids,
  });

  final ShareLinkKind kind;
  final String subject;
  final String? topic;

  /// Ordered list of question JSON maps (`uuid` + full display fields).
  final List<Map<String, dynamic>> uuids;

  List<String> get orderedQuestionUuids =>
      uuids.map((m) => m['uuid'] as String).toList();
}

class SharedSessionFirestoreRepository {
  SharedSessionFirestoreRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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
    return SharedSessionDocument(
      kind: kind,
      subject: subject,
      topic: (topic != null && topic.isNotEmpty) ? topic : null,
      uuids: uuids,
    );
  }
}
