import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';

/// Stable `game_name` values for revision-game Firebase events.
abstract final class RevisionGameNames {
  static const gamesHub = 'games_hub';
  static const timelineSorter = 'timeline_sorter';
  static const oddOneOut = 'odd_one_out';
  static const factOrBluff = 'fact_or_bluff';
  static const connectTheDots = 'connect_the_dots';
  static const duel = 'duel';
  static const memoryPairs = 'memory_pairs';
}

/// Logs [GameScreenOpenedEvent] once when the widget mounts.
void useGameScreenOpenedAnalytics(WidgetRef ref, String gameName) {
  useEffect(() {
    Analytics.track(ref, GameScreenOpenedEvent(gameName: gameName));
    return null;
  }, const []);
}

/// Logs [GameStartedEvent] when a session becomes playable (after how-to),
/// and [GameRoundFinishedEvent] when that session completes. Deduped by
/// [sessionKey] so Play again fires a new start/finish pair.
void useGameSessionAnalytics({
  required WidgetRef ref,
  required String gameName,
  required bool readyToStart,
  required bool sessionComplete,
  required int correctCount,
  required int totalRounds,
  required String? sessionKey,
}) {
  final lastStartedKey = useRef<String?>(null);
  final lastFinishedKey = useRef<String?>(null);

  useEffect(() {
    final key = sessionKey;
    if (!readyToStart || key == null || key.isEmpty || sessionComplete) {
      return null;
    }
    if (lastStartedKey.value == key) return null;
    lastStartedKey.value = key;
    Analytics.track(
      ref,
      GameStartedEvent(gameName: gameName, totalRounds: totalRounds),
    );
    return null;
  }, [readyToStart, sessionComplete, sessionKey, totalRounds]);

  useEffect(() {
    final key = sessionKey;
    if (!sessionComplete || key == null || key.isEmpty) return null;
    if (lastFinishedKey.value == key) return null;
    lastFinishedKey.value = key;
    Analytics.track(
      ref,
      GameRoundFinishedEvent(
        gameName: gameName,
        correctCount: correctCount,
        totalRounds: totalRounds,
      ),
    );
    return null;
  }, [sessionComplete, sessionKey, correctCount, totalRounds]);
}
