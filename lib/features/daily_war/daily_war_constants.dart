/// Constants for Daily War sessions and routing.
abstract final class DailyWarConstants {
  DailyWarConstants._();

  static const sessionSubject = 'daily_war';
  static const analyticsLive = 'daily_war';
  static const analyticsUnranked = 'daily_war_unranked';

  static const functionsRegion = 'asia-south1';

  /// RTDB path: `daily_war_counts/{dateId}` → `{ lobby, writing }`.
  static const rtdbCountsRoot = 'daily_war_counts';

  /// FCM topic when rollout is everyone.
  static const broadcastFcmTopic = 'upsc_wars_daily_war';

  /// FCM topic when rollout is admins-only.
  static const adminBroadcastFcmTopic = 'upsc_wars_daily_war_admins';

  /// FCM `data.kind` for Daily War opens.
  static const fcmKind = 'daily_war';

  /// Prepare-style phases land on home with the War hero; lobby/results stay
  /// on `/daily-war`.
  static bool fcmPhaseOpensHomeHero(String? phase) {
    switch (phase?.trim().toLowerCase()) {
      case 'morning':
      case 'reminder_30':
        return true;
      default:
        return false;
    }
  }

  /// How often clients poll RTDB live counts during lobby / live.
  /// Default RTDB lobby/writing poll interval (overridable via Remote Config).
  static const liveCountPollSeconds = 15;

  static bool isDailyWarFeatureKey(String? key) =>
      key == analyticsLive || key == analyticsUnranked;

  static bool isUnrankedFeatureKey(String? key) => key == analyticsUnranked;
}

String dailyWarLobbyRoute() => '/daily-war';

String dailyWarHistoryRoute() => '/daily-war/history';

String dailyWarBadgesRoute() => '/daily-war/history/badges';

String dailyWarHistoryDetailRoute(String dateId) =>
    '/daily-war/history/$dateId';

String dailyWarHistoryReviseRoute(String dateId) =>
    '/daily-war/history/$dateId/revise';

String dailyWarLeaderboardRoute(String dateId) =>
    '/daily-war/history/$dateId/leaderboard';

String dailyWarResultsRoute(String sessionId) =>
    '/daily-war/results/$sessionId';
