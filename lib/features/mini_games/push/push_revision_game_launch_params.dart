import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_revision_game_fcm.dart';

/// Launch inputs for push / deep link → Games hub + config sheet.
class PushRevisionGameLaunchParams {
  const PushRevisionGameLaunchParams({required this.gameId});

  /// Stable id (`timeline_sorter`, `duel`, …).
  final String gameId;

  bool get isValid =>
      PushRevisionGameFcm.normalizeGameId(gameId) != null &&
      gameId.trim().isNotEmpty;

  String? get validationError {
    final id = gameId.trim();
    if (id.isEmpty) return 'Missing game id.';
    if (PushRevisionGameFcm.normalizeGameId(id) == null) {
      return 'Unknown game: $id';
    }
    return null;
  }

  Map<String, String> toQueryParameters({int? nonce}) => {
    PushRevisionGameFcm.queryKeyConfig:
        PushRevisionGameFcm.normalizeGameId(gameId) ?? gameId.trim(),
    PushRevisionGameFcm.queryKeyNonce:
        (nonce ?? DateTime.now().millisecondsSinceEpoch).toString(),
  };

  /// `/games?config=<gameId>&t=<nonce>` — hub opens the config sheet for [gameId].
  String get hubLocation {
    final uri = Uri(path: '/games', queryParameters: toQueryParameters());
    return uri.toString();
  }

  static PushRevisionGameLaunchParams fromQuery(Map<String, String> q) {
    final raw =
        q[PushRevisionGameFcm.queryKeyConfig] ??
        q[PushRevisionGameFcm.dataKeyGame] ??
        '';
    return PushRevisionGameLaunchParams(
      gameId: PushRevisionGameFcm.normalizeGameId(raw) ?? raw.trim(),
    );
  }

  static PushRevisionGameLaunchParams fromRemoteMessage(RemoteMessage message) {
    return PushRevisionGameLaunchParams(
      gameId: PushRevisionGameFcm.gameIdFromData(message.data) ?? '',
    );
  }
}
