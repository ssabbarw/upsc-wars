import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/community_bucket_utils.dart';
import '../domain/community_legacy_contract.dart';
import '../domain/entities/community_user.dart';

class CommunityRepository {
  CommunityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// `buckets/{yyyy-m}/{day}/{0|3|…|21}` for “now” (same path as [fetchRecentUsers] offset 0).
  DocumentReference<Map<String, dynamic>> presenceBucketDocRefNow() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    return _firestore
        .collection(CommunityLegacyContract.bucketsCollection)
        .doc(CommunityBucketUtils.yearMonthDocIdForTimestamp(ts))
        .collection('${now.day}')
        .doc(CommunityBucketUtils.bucketForTimestamp(ts));
  }

  /// Top-level field key is lowercased [emailFieldKey]; value is a legacy-shaped map.
  Future<void> upsertUserInCurrentPresenceBucket({
    required String emailFieldKey,
    required Map<String, dynamic> userPayload,
  }) async {
    final docRef = presenceBucketDocRefNow();
    if (kDebugMode) {
      final path = docRef.path;
      final segments = path.split('/');
      final bucketId = segments.length >= 2
          ? segments[segments.length - 1]
          : '?';
      debugPrint(
        '[CommunityPresence] merge user field on doc=$path '
        '(bucket=$bucketId, topLevelField=$emailFieldKey)',
      );
    }
    await docRef.set({emailFieldKey: userPayload}, SetOptions(merge: true));
  }

  /// One 3-hour presence doc. Empty windows return `[]` so Recents can walk
  /// the next older bucket instead of substituting `users`.
  Future<List<CommunityUser>> fetchRecentUsers({int bucketOffset = 0}) async {
    if (bucketOffset >= CommunityBucketUtils.maxBucketLookback) return const [];
    final timestamp = DateTime.now()
        .subtract(
          Duration(
            hours: bucketOffset * CommunityBucketUtils.bucketWindowHours,
          ),
        )
        .millisecondsSinceEpoch;
    final now = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final bucketDoc = _firestore
        .collection(CommunityLegacyContract.bucketsCollection)
        .doc(CommunityBucketUtils.yearMonthDocIdForTimestamp(timestamp))
        .collection('${now.day}')
        .doc(
          CommunityBucketUtils.bucketForTimestamp(now.millisecondsSinceEpoch),
        );

    final snap = await bucketDoc.get();
    if (!snap.exists) return const [];
    final data = snap.data();
    if (data == null || data.isEmpty) return const [];

    final users = <CommunityUser>[];
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        users.add(communityUserFromLegacyMap(entry.key, value));
      } else if (value is Map) {
        users.add(
          communityUserFromLegacyMap(
            entry.key,
            Map<String, dynamic>.from(value),
          ),
        );
      } else if (value is String) {
        final decoded = decodeCommunityJsonPayload(value);
        if (decoded != null) {
          users.add(communityUserFromLegacyMap(entry.key, decoded));
        }
      }
    }

    users.sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
    return dedupeCommunityUsersByLatest(users);
  }

  /// Loads `users/{email}` for profile display (e.g. chat header).
  Future<CommunityUser?> fetchCommunityUserByEmail(String email) async {
    final normalized = email.toLowerCase().trim();
    if (normalized.isEmpty) return null;
    final snap = await _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .doc(normalized)
        .get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return communityUserFromLegacyMap(normalized, data);
  }

  /// Display names for chat list rows. Never derived from the email local-part.
  Future<Map<String, String>> fetchDisplayNamesByEmails(
    Iterable<String> emails,
  ) async {
    final names = <String, String>{};
    final ids = emails
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return names;
    const chunkSize = 20;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, i + chunkSize > ids.length ? ids.length : i + chunkSize);
      final snaps = await Future.wait(
        chunk.map(
          (id) => _firestore
              .collection(CommunityLegacyContract.usersCollection)
              .doc(id)
              .get(),
        ),
      );
      for (var j = 0; j < snaps.length; j++) {
        final data = snaps[j].data();
        if (data == null) continue;
        final user = communityUserFromLegacyMap(chunk[j], data);
        final name = user.name.trim();
        if (name.isNotEmpty) names[chunk[j]] = name;
      }
    }
    return names;
  }

  Future<List<CommunityUser>> fetchChallengers() async {
    final minTs = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    final query = await _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .where(
          CommunityLegacyContract.lastOpenChallengeAt,
          isGreaterThanOrEqualTo: minTs,
        )
        .get();

    final users =
        query.docs
            .map((doc) => communityUserFromLegacyMap(doc.id, doc.data()))
            .toList()
          ..sort(
            (a, b) => (b.openChallengeTimestamp ?? 0).compareTo(
              a.openChallengeTimestamp ?? 0,
            ),
          );
    return users;
  }

  /// `users/{ownerEmail}/blocked/{otherEmail}` — owner read/write; others may read only the doc
  /// whose id is their own email (see Firestore rules) to detect "has this user blocked me?".
  CollectionReference<Map<String, dynamic>> blockedUsersCol(String ownerEmail) {
    return _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .doc(ownerEmail.toLowerCase().trim())
        .collection('blocked');
  }

  Stream<Set<String>> watchBlockedEmails(String ownerEmail) {
    final normalized = ownerEmail.toLowerCase().trim();
    if (normalized.isEmpty) {
      return Stream.value(const <String>{});
    }
    return blockedUsersCol(normalized).snapshots().map(
          (snap) => snap.docs.map((d) => d.id.toLowerCase()).toSet(),
        );
  }

  Future<bool> isUserBlocked({
    required String ownerEmail,
    required String otherEmail,
  }) async {
    final owner = ownerEmail.toLowerCase().trim();
    final other = otherEmail.toLowerCase().trim();
    if (owner.isEmpty || other.isEmpty) return false;
    final snap = await blockedUsersCol(owner).doc(other).get();
    return snap.exists;
  }

  Future<void> setUserBlocked({
    required String ownerEmail,
    required String otherEmail,
    required bool blocked,
  }) async {
    final owner = ownerEmail.toLowerCase().trim();
    final other = otherEmail.toLowerCase().trim();
    if (owner.isEmpty || other.isEmpty || owner == other) return;
    final ref = blockedUsersCol(owner).doc(other);
    if (blocked) {
      await ref.set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.delete();
    }
  }

  Future<void> updateCommunityVisibility({
    required String email,
    required bool acceptingBattleInvites,
    required bool showInBattleStatus,
  }) async {
    final isInBattleTill = showInBattleStatus
        ? DateTime.now().add(const Duration(minutes: 12)).millisecondsSinceEpoch
        : DateTime.now()
              .subtract(const Duration(minutes: 50))
              .millisecondsSinceEpoch;

    await _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .doc(email.toLowerCase())
        .set({
          CommunityLegacyContract.acceptingBattleInvites:
              acceptingBattleInvites,
          CommunityLegacyContract.isInBattle: isInBattleTill,
          CommunityLegacyContract.lastOnlineTime:
              DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
  }
}

List<CommunityUser> dedupeCommunityUsersByLatest(List<CommunityUser> users) {
  final map = <String, CommunityUser>{};
  for (final user in users) {
    final existing = map[user.email];
    if (existing == null || user.lastOnlineTime > existing.lastOnlineTime) {
      map[user.email] = user;
    }
  }
  final values = map.values.toList()
    ..sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
  return values;
}

Map<String, dynamic>? decodeCommunityJsonPayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  } catch (_) {
    return null;
  }
}
