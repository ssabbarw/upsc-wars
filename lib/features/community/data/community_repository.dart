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
    if (!snap.exists) {
      return bucketOffset == 0
          ? _fetchRecentUsersFromUsersCollection()
          : const [];
    }
    final data = snap.data();
    if (data == null || data.isEmpty) {
      return bucketOffset == 0
          ? _fetchRecentUsersFromUsersCollection()
          : const [];
    }

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

  Future<List<CommunityUser>> _fetchRecentUsersFromUsersCollection() async {
    final minTs = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    final query = await _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .where(
          CommunityLegacyContract.lastOnlineTime,
          isGreaterThanOrEqualTo: minTs,
        )
        .orderBy(CommunityLegacyContract.lastOnlineTime, descending: true)
        .limit(100)
        .get();

    final users = query.docs
        .map((doc) => communityUserFromLegacyMap(doc.id, doc.data()))
        .toList();
    if (users.isNotEmpty) {
      return dedupeCommunityUsersByLatest(users);
    }

    final unfiltered = await _firestore
        .collection(CommunityLegacyContract.usersCollection)
        .limit(100)
        .get();

    final fallbackUsers =
        unfiltered.docs
            .map((doc) => communityUserFromLegacyMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
    return dedupeCommunityUsersByLatest(fallbackUsers);
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
