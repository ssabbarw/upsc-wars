import 'package:upsc_wars/core/constants/app_constants.dart';

import 'entities/community_user.dart';

abstract final class CommunityLegacyContract {
  // Collections
  static const usersCollection = 'users';
  static const bucketsCollection = 'buckets';

  // User document fields (legacy Firestore)
  static const email = 'email';
  static const name = 'name';
  static const photoUrl = 'photoURL';
  static const lastOnlineTime = 'lastOnlineTime';
  static const appVersion = 'appVersion';
  /// Device model string written to `buckets` presence payloads (e.g. Android model).
  static const phoneModel = 'phoneModel';
  static const acceptingBattleInvites = 'acceptingBattleInvites';
  static const isInBattle = 'isInBattle';
  static const telegram = 'telegram';
  static const instagram = 'insta';
  static const optional = 'optional';
  static const status = 'my_status';
  static const lastOpenChallengeAt = 'kKeyLastOpenChallengeFloatDate';
  static const lastOpenChallengeSubject = 'kKeyLastOpenChallengeSubject';
}

CommunityUser communityUserFromLegacyMap(
  String documentId,
  Map<String, dynamic> map,
) {
  final rawEmail = (map[CommunityLegacyContract.email] as String?)?.trim();
  final email = rawEmail?.isNotEmpty == true ? rawEmail! : documentId;
  final rawName = (map[CommunityLegacyContract.name] as String?)?.trim();
  final photo = (map[CommunityLegacyContract.photoUrl] as String?)?.trim();

  return CommunityUser(
    email: email.toLowerCase(),
    name: rawName?.isNotEmpty == true ? rawName! : 'UPSC Warrior',
    photoUrl: photo?.isNotEmpty == true
        ? photo!
        : AppConstants.defaultProfilePhotoUrl,
    lastOnlineTime:
        (map[CommunityLegacyContract.lastOnlineTime] as num?)?.toInt() ?? 0,
    acceptingBattleInvites:
        (map[CommunityLegacyContract.acceptingBattleInvites] as bool?) ?? true,
    isInBattleTill: (map[CommunityLegacyContract.isInBattle] as num?)?.toInt(),
    appVersion: map[CommunityLegacyContract.appVersion] as String?,
    telegram: map[CommunityLegacyContract.telegram] as String?,
    instagram: map[CommunityLegacyContract.instagram] as String?,
    optionalContact: map[CommunityLegacyContract.optional] as String?,
    status: map[CommunityLegacyContract.status] as String?,
    openChallengeTimestamp:
        (map[CommunityLegacyContract.lastOpenChallengeAt] as num?)?.toInt(),
    openChallengeSubject:
        map[CommunityLegacyContract.lastOpenChallengeSubject] as String?,
  );
}
