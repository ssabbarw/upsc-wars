import 'package:upsc_wars/core/domain/entities/active_session.dart';

import 'battle_participant.dart';

class BattleSession {
  const BattleSession({
    required this.id,
    required this.baseSession,
    required this.player,
    required this.opponent,
    required this.playerResponsesByQuestion,
    required this.opponentResponsesByQuestion,
  });

  final String id;
  final ActiveSession baseSession;
  final BattleParticipant player;
  final BattleParticipant opponent;
  final Map<String, String> playerResponsesByQuestion;
  final Map<String, String> opponentResponsesByQuestion;

  BattleSession copyWith({
    ActiveSession? baseSession,
    Map<String, String>? playerResponsesByQuestion,
    Map<String, String>? opponentResponsesByQuestion,
  }) {
    return BattleSession(
      id: id,
      baseSession: baseSession ?? this.baseSession,
      player: player,
      opponent: opponent,
      playerResponsesByQuestion:
          playerResponsesByQuestion ?? this.playerResponsesByQuestion,
      opponentResponsesByQuestion:
          opponentResponsesByQuestion ?? this.opponentResponsesByQuestion,
    );
  }
}
