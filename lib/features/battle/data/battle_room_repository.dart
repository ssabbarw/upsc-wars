import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';

/// Firestore `joined_users` writes and legacy response encoding for battles.
class BattleRoomRepository {
  const BattleRoomRepository();

  /// Call when the local player submits the battle paper so spectators can
  /// treat unanswered slots as final (Firestore `responses` uses `0` there).
  Future<void> markBattlePaperSubmitted({
    required String sessionId,
    required String participantDocId,
  }) async {
    await BattleFirestorePaths.joinedUsersCol(sessionId)
        .doc(participantDocId)
        .set(
          {'battle_paper_submitted': true},
          SetOptions(merge: true),
        );
  }

  Future<void> upsertParticipantResponses({
    required String sessionId,
    required String participantDocId,
    required List<TestQuestion> questions,
    required Map<String, String> responsesByQuestionUuid,
  }) async {
    final responses = List<int>.filled(questions.length, 0);
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selected = responsesByQuestionUuid[q.uuid];
      responses[i] = optionToLegacyResponseInt(selected);
    }
    await BattleFirestorePaths.joinedUsersCol(sessionId)
        .doc(participantDocId)
        .set(
          {
            'game_progress_status': 'Active',
            'responses': responses,
          },
          SetOptions(merge: true),
        );
  }

  static int optionToLegacyResponseInt(String? option) {
    switch (option) {
      case 'a':
        return 1;
      case 'b':
        return 2;
      case 'c':
        return 3;
      case 'd':
        return 4;
      default:
        return 0;
    }
  }

  static String? legacyResponseIntToOption(Object? raw) {
    final value = int.tryParse(raw.toString());
    switch (value) {
      case 1:
        return 'a';
      case 2:
        return 'b';
      case 3:
        return 'c';
      case 4:
        return 'd';
      default:
        return null;
    }
  }
}
