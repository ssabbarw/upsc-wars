import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/features/battle/data/battle_match_firestore_service.dart';
import 'package:upsc_wars/features/battle/data/battle_room_repository.dart';
import 'package:upsc_wars/features/battle/domain/battle_opponent_policy.dart';
import 'package:upsc_wars/features/battle/domain/battle_scoring.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';

/// Builds a [BattleResultPayload] from per-question selections (names from [seed]).
BattleResultPayload battleResultPayloadFromQuestionMaps({
  required BattleResultPayload seed,
  required List<TestQuestion> questions,
  required Map<String, String> playerByUuid,
  required Map<String, String> opponentByUuid,
}) {
  bool? outcomeFor(String? selected, String correct) {
    if (selected == null) return null;
    return selected.toLowerCase() == correct.toLowerCase();
  }

  final playerScore = calculateUpscBattleScore(
    questions: questions,
    selectedOptionByQuestion: playerByUuid,
  );
  final opponentScore = calculateUpscBattleScore(
    questions: questions,
    selectedOptionByQuestion: opponentByUuid,
  );

  return BattleResultPayload(
    sessionId: seed.sessionId,
    playerName: seed.playerName,
    opponentName: seed.opponentName,
    playerScore: playerScore.points,
    opponentScore: opponentScore.points,
    playerOutcomeByQuestion: questions
        .map(
          (q) => outcomeFor(playerByUuid[q.uuid], q.correctOption),
        )
        .toList(),
    opponentOutcomeByQuestion: questions
        .map(
          (q) => outcomeFor(opponentByUuid[q.uuid], q.correctOption),
        )
        .toList(),
  );
}

BattleResultPayload battleResultPayloadFromSpectate(BattleSpectateState s) {
  return BattleResultPayload(
    sessionId: s.sessionId,
    playerName: s.playerName,
    opponentName: s.opponentName,
    playerScore: s.playerPoints,
    opponentScore: s.opponentPoints,
    playerOutcomeByQuestion: List<bool?>.from(s.playerOutcomes),
    opponentOutcomeByQuestion: List<bool?>.from(s.opponentOutcomes),
  );
}

Map<String, String> battlePlayerResponsesFromActiveSession(ActiveSession base) {
  final byQuestion = <String, String>{};
  for (final q in base.questions) {
    final sel = q.selectedOption;
    if (sel == null) continue;
    byQuestion[q.uuid] = sel;
  }
  return byQuestion;
}

Map<String, String> battleOpponentResponsesFromJoinedDoc(
  Object? responsesRaw,
  List<TestQuestion> questions,
) {
  final byQuestion = <String, String>{};
  if (responsesRaw is! List) return byQuestion;
  for (var i = 0; i < responsesRaw.length && i < questions.length; i++) {
    final mapped = BattleRoomRepository.legacyResponseIntToOption(
      responsesRaw[i],
    );
    if (mapped != null) {
      byQuestion[questions[i].uuid] = mapped;
    }
  }
  return byQuestion;
}

/// Firestore `joined_users` doc id for the opponent (mirrors battle session init).
String resolveBattleOpponentDocId({
  required String playerIdLower,
  required DocumentSnapshot<Map<String, dynamic>>? matchSnap,
}) {
  var opponentId = BattleOpponentPolicy.syntheticBotDocId;
  if (matchSnap == null || !matchSnap.exists) return opponentId;
  final d = matchSnap.data()!;
  final mode = d['battle_mode'] as String?;
  if (mode == BattleMatchFirestoreService.battleModeHuman) {
    final host = (d['host_email'] as String?)?.toLowerCase() ?? '';
    final guest = (d['guest_email'] as String?)?.toLowerCase() ?? '';
    if (playerIdLower == host && guest.isNotEmpty) {
      opponentId = guest;
    } else if (playerIdLower == guest && host.isNotEmpty) {
      opponentId = host;
    }
  }
  return opponentId;
}
