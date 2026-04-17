/// Opponent selected from Community (or similar) for a human 1v1 battle.
class BattleInviteTarget {
  const BattleInviteTarget({
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  /// Lowercase email — Firestore `users` doc id and `joined_users` doc id.
  final String email;
  final String displayName;
  final String? photoUrl;
}
