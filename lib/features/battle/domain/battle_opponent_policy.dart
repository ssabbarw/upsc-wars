/// Human vs bot: bot answers use the synthetic Firestore doc id [syntheticBotDocId].
class BattleOpponentPolicy {
  BattleOpponentPolicy._();

  static const syntheticBotDocId = 'opponent';

  static bool isBotOpponent(String opponentId) =>
      opponentId == syntheticBotDocId;
}
