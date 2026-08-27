abstract final class DailyCaAdminConstants {
  DailyCaAdminConstants._();

  static const functionsRegion = 'asia-south1';
  static const fcmKind = 'daily_ca_review';
  static const minPublish = 5;
  static const maxPublish = 10;
  static const generateTimeout = Duration(minutes: 30);

  static String reviewPath(String isoDate) =>
      '/internal/daily-ca-review/$isoDate';
}

/// User-facing Daily Current Affairs paper push (not the admin review FCM).
abstract final class DailyCaConstants {
  DailyCaConstants._();

  static const broadcastFcmTopic = 'upsc_wars_daily_ca';
  static const fcmKind = 'daily_ca';
  static const functionsRegion = DailyCaAdminConstants.functionsRegion;
}

String dailyCaResultsRoute(String sessionId) =>
    '/daily-ca/results/$sessionId';

String dailyCaLeaderboardRoute(String dateId) =>
    '/daily-ca/$dateId/leaderboard';
