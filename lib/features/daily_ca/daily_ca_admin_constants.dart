abstract final class DailyCaAdminConstants {
  DailyCaAdminConstants._();

  static const functionsRegion = 'asia-south1';
  static const fcmKind = 'daily_ca_review';
  static const minPublish = 5;
  static const maxPublish = 10;

  static String reviewPath(String isoDate) =>
      '/internal/daily-ca-review/$isoDate';
}
