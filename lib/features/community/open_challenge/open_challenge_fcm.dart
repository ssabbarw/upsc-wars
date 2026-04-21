/// FCM `data` keys for [BattleMessagingService] routing (keep in sync with
/// `functions/index.js` `onOpenChallengeWritten`).
abstract final class OpenChallengeFcm {
  OpenChallengeFcm._();

  static const kind = 'open_challenge';
  static const challengeId = 'challengeId';
}
