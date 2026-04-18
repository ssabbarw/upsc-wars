import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:upsc_wars/features/community/domain/community_legacy_contract.dart';
import 'package:upsc_wars/features/community/providers/community_providers.dart';

/// On app open (signed-in), merges the current user into the active `buckets`
/// snapshot doc under their email key so Recents can read a dense map.
class CommunityBucketPresenceService {
  CommunityBucketPresenceService._();

  static Future<void> syncForCurrentUser(WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (user == null || email == null || email.isEmpty) return;

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection(CommunityLegacyContract.usersCollection)
          .doc(email)
          .get();
      final d = userSnap.data() ?? <String, dynamic>{};

      final name =
          _nonEmpty(user.displayName) ??
          _nonEmpty(d[CommunityLegacyContract.name] as String?) ??
          'UPSC Warrior';

      final optional = _nullableString(
        d[CommunityLegacyContract.optional] as String?,
      );
      final myStatus = _nullableString(
        d[CommunityLegacyContract.status] as String?,
      );
      final telegram = _nullableString(
        d[CommunityLegacyContract.telegram] as String?,
      );
      final insta = _nullableString(
        d[CommunityLegacyContract.instagram] as String?,
      );

      final isInBattleRaw = d[CommunityLegacyContract.isInBattle];
      final Object? isInBattle = isInBattleRaw == null
          ? null
          : (isInBattleRaw is num ? isInBattleRaw.toInt() : null);

      final phoneModel = await _readPhoneModel();
      final pkg = await PackageInfo.fromPlatform();

      final payload = <String, dynamic>{
        'name': name,
        'optional': optional,
        'email': email,
        'telegram': telegram,
        'insta': insta,
        'photoURL': _nullableString(user.photoURL),
        'my_status': myStatus,
        'isInBattle': isInBattle,
        CommunityLegacyContract.phoneModel: phoneModel,
        'appVersion': pkg.version,
        'lastOnlineTime': DateTime.now().millisecondsSinceEpoch,
      };

      await ref
          .read(communityRepositoryProvider)
          .upsertUserInCurrentPresenceBucket(
            emailFieldKey: email,
            userPayload: payload,
          );
    } catch (e, st) {
      debugPrint('CommunityBucketPresenceService.syncForCurrentUser: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static String? _nullableString(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static Future<String> _readPhoneModel() async {
    if (kIsWeb) return 'web';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await DeviceInfoPlugin().androidInfo;
        return info.model;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {}
    return defaultTargetPlatform.name;
  }
}
