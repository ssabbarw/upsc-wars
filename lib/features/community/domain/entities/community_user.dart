class CommunityUser {
  const CommunityUser({
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.lastOnlineTime,
    required this.acceptingBattleInvites,
    required this.isInBattleTill,
    required this.appVersion,
    required this.telegram,
    required this.instagram,
    required this.optionalContact,
    required this.status,
    required this.openChallengeTimestamp,
    required this.openChallengeSubject,
  });

  final String email;
  final String name;
  final String photoUrl;
  final int lastOnlineTime;
  final bool acceptingBattleInvites;
  final int? isInBattleTill;
  final String? appVersion;
  final String? telegram;
  final String? instagram;
  final String? optionalContact;
  final String? status;
  final int? openChallengeTimestamp;
  final String? openChallengeSubject;

  bool get isInBattle {
    final till = isInBattleTill;
    if (till == null) return false;
    return till > DateTime.now().millisecondsSinceEpoch;
  }
}
