/// FCM **data** payload for opening the Games hub + config sheet for a game.
///
/// Required:
/// * `kind` = [PushRevisionGameFcm.kind] (`revision_game`)
/// * `game` — which game (aliases accepted; see [PushRevisionGameFcm.gameIdFromData])
///
/// Supported `game` values:
/// * `timeline_sorter` / `timeline-sorter`
/// * `odd_one_out` / `odd-one-out`
/// * `fact_or_bluff` / `fact-or-bluff`
/// * `connect_the_dots` / `connect-the-dots`
/// * `duel` / `1v1_duel`
/// * `memory_pairs` / `memory-pairs` (opens catalog; no config sheet)
///
/// Tap opens `/games?config=<game>`, then the hub auto-shows that game's
/// session config bottom sheet (when the game uses one).
abstract final class PushRevisionGameFcm {
  static const kind = 'revision_game';

  static const dataKeyKind = 'kind';
  static const dataKeyGame = 'game';
  static const dataKeyGameId = 'game_id';
  static const dataKeyId = 'id';

  /// Query key on `/games` that triggers the config sheet.
  static const queryKeyConfig = 'config';

  /// Optional nonce so repeat pushes for the same game still re-trigger.
  static const queryKeyNonce = 't';

  /// Resolves a stable game id from FCM custom data, if present.
  static String? gameIdFromData(Map<String, dynamic> data) {
    for (final key in [dataKeyGame, dataKeyGameId, dataKeyId]) {
      final raw = data[key];
      final s = raw?.toString().trim();
      if (s != null && s.isNotEmpty) return normalizeGameId(s);
    }
    return null;
  }

  /// Maps free-form FCM / deep-link slugs to [RevisionGameNames]-style ids.
  static String? normalizeGameId(String raw) {
    final s = raw.trim().toLowerCase().replaceAll('-', '_');
    switch (s) {
      case 'timeline_sorter':
      case 'timelinesorter':
        return 'timeline_sorter';
      case 'odd_one_out':
      case 'oddoneout':
        return 'odd_one_out';
      case 'fact_or_bluff':
      case 'factorbluff':
        return 'fact_or_bluff';
      case 'connect_the_dots':
      case 'connectthedots':
        return 'connect_the_dots';
      case 'duel':
      case '1v1_duel':
      case '1v1duel':
        return 'duel';
      case 'memory_pairs':
      case 'memorypairs':
        return 'memory_pairs';
      default:
        return null;
    }
  }
}
