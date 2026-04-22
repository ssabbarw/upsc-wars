import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';

/// Host-side Firestore setup before the battle screen loads.
class BattleMatchFirestoreService {
  const BattleMatchFirestoreService();

  static Future<void> _ensureSignedInForFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in with Google before using battle sync.');
    }
    await user.getIdToken(true);
  }

  static const battleModeHuman = 'human';
  static const battleModeBot = 'bot';

  static const fieldGuestReady = 'guest_ready';

  /// Human 1v1: match doc + host and guest `joined_users` stubs (guest merges on join).
  Future<void> primeHumanMatch({
    required String sessionId,
    required List<String> questionUuids,
    required String hostEmail,
    required String hostDisplayName,
    required String? hostPhotoUrl,
    required String guestEmail,
    required String guestDisplayName,
    required String subject,
  }) async {
    await _ensureSignedInForFirestore();
    final host = hostEmail.toLowerCase();
    final guest = guestEmail.toLowerCase();
    final matchRef = BattleFirestorePaths.matchDoc(sessionId);
    final emptyResponses = List<int>.filled(questionUuids.length, 0);

    await matchRef.set({
      'battle_mode': battleModeHuman,
      'host_email': host,
      'host_display_name': hostDisplayName,
      'guest_email': guest,
      'guest_display_name': guestDisplayName,
      'subject': subject,
      'question_uuids': questionUuids,
      'question_indexes': List<int>.generate(questionUuids.length, (i) => i),
      'lets_start_game': false,
      fieldGuestReady: false,
      'num_of_players_joined': 1,
      'fcm_token': null,
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.joinedUsersCol(sessionId).doc(host).set({
      'display_name': hostDisplayName,
      'profile_pic': hostPhotoUrl,
      'game_progress_status': 'Active',
      'responses': emptyResponses,
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.gameOverCol(sessionId).doc(host).set({
      'game_progress_status': 'Active',
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.joinedUsersCol(sessionId).doc(guest).set({
      'display_name': guestDisplayName,
      'profile_pic': 'no_image',
      'game_progress_status': 'Active',
      'responses': emptyResponses,
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.gameOverCol(sessionId).doc(guest).set({
      'game_progress_status': 'Active',
    }).timeout(const Duration(seconds: 12));
  }

  /// Bot battle: full room (host + synthetic opponent doc).
  Future<void> createBotMatch({
    required String sessionId,
    required List<String> questionUuids,
    required String hostEmail,
    required String hostDisplayName,
    required String? hostPhotoUrl,
    required String opponentDocId,
    required String opponentDisplayName,
    required String subject,
  }) async {
    await _ensureSignedInForFirestore();
    final host = hostEmail.toLowerCase();
    final matchRef = BattleFirestorePaths.matchDoc(sessionId);
    final emptyResponses = List<int>.filled(questionUuids.length, 0);

    await matchRef.set({
      'battle_mode': battleModeBot,
      'host_email': host,
      'host_display_name': hostDisplayName,
      'guest_email': null,
      'guest_display_name': opponentDisplayName,
      'subject': subject,
      'question_uuids': questionUuids,
      'question_indexes': List<int>.generate(questionUuids.length, (i) => i),
      'lets_start_game': true,
      'num_of_players_joined': 2,
      'fcm_token': null,
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.joinedUsersCol(sessionId).doc(host).set({
      'display_name': hostDisplayName,
      'profile_pic': hostPhotoUrl,
      'game_progress_status': 'Active',
      'responses': emptyResponses,
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.gameOverCol(sessionId).doc(host).set({
      'game_progress_status': 'Active',
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.joinedUsersCol(sessionId).doc(opponentDocId).set({
      'display_name': opponentDisplayName,
      'profile_pic': 'no_image',
      'game_progress_status': 'Active',
      'responses': emptyResponses,
    }).timeout(const Duration(seconds: 12));

    await BattleFirestorePaths.gameOverCol(sessionId).doc(opponentDocId).set({
      'game_progress_status': 'Active',
    }).timeout(const Duration(seconds: 12));
  }

  /// Guest updates profile fields on their participant doc (optional photo).
  Future<void> mergeGuestProfile({
    required String sessionId,
    required String guestEmail,
    required String displayName,
    String? photoUrl,
  }) async {
    await _ensureSignedInForFirestore();
    final guest = guestEmail.toLowerCase();
    await BattleFirestorePaths.joinedUsersCol(sessionId).doc(guest).set(
      {
        'display_name': displayName,
        'profile_pic': (photoUrl != null && photoUrl.isNotEmpty)
            ? photoUrl
            : 'no_image',
      },
      SetOptions(merge: true),
    ).timeout(const Duration(seconds: 12));
  }

  /// Guest finished local import + profile; host lobby shows them as joined.
  Future<void> signalGuestLobbyReady(String sessionId) async {
    await _ensureSignedInForFirestore();
    await BattleFirestorePaths.matchDoc(sessionId).update({
      fieldGuestReady: true,
      'num_of_players_joined': 2,
    }).timeout(const Duration(seconds: 12));
  }

  /// Host starts the timed battle for both players (`lets_start_game`).
  Future<void> signalHostStartedBattle(String sessionId) async {
    await _ensureSignedInForFirestore();
    await BattleFirestorePaths.matchDoc(sessionId).update({
      'lets_start_game': true,
    }).timeout(const Duration(seconds: 12));
  }
}
