/// Constants for Daily War sessions and routing.
abstract final class DailyWarConstants {
  DailyWarConstants._();

  static const sessionSubject = 'daily_war';
  static const analyticsLive = 'daily_war';
  static const analyticsUnranked = 'daily_war_unranked';

  static const functionsRegion = 'asia-south1';

  static bool isDailyWarFeatureKey(String? key) =>
      key == analyticsLive || key == analyticsUnranked;

  static bool isUnrankedFeatureKey(String? key) => key == analyticsUnranked;
}

String dailyWarLobbyRoute() => '/daily-war';

String dailyWarHistoryRoute() => '/daily-war/history';

String dailyWarResultsRoute(String sessionId) =>
    '/daily-war/results/$sessionId';
