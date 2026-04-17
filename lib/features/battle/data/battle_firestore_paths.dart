import 'package:cloud_firestore/cloud_firestore.dart';

/// Flat Firestore layout for battles so [sessionId] works across days and deep links.
///
/// `rooms/{y}/{m}/...` is deprecated for new writes; use [matchDoc] only.
class BattleFirestorePaths {
  BattleFirestorePaths._();

  static const collection = 'battle_matches';
  static const joinedUsers = 'joined_users';
  static const gameOverStatuses = 'joined_users_game_over_statuses';

  static DocumentReference<Map<String, dynamic>> matchDoc(String sessionId) {
    return FirebaseFirestore.instance.collection(collection).doc(sessionId);
  }

  static CollectionReference<Map<String, dynamic>> joinedUsersCol(
    String sessionId,
  ) {
    return matchDoc(sessionId).collection(joinedUsers);
  }

  static CollectionReference<Map<String, dynamic>> gameOverCol(
    String sessionId,
  ) {
    return matchDoc(sessionId).collection(gameOverStatuses);
  }
}
