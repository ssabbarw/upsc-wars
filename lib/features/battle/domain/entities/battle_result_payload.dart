class BattleResultPayload {
  const BattleResultPayload({
    required this.sessionId,
    required this.playerName,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.playerOutcomeByQuestion,
    required this.opponentOutcomeByQuestion,
  });

  final String sessionId;
  final String playerName;
  final String opponentName;
  final double playerScore;
  final double opponentScore;
  final List<bool?> playerOutcomeByQuestion;
  final List<bool?> opponentOutcomeByQuestion;
}
