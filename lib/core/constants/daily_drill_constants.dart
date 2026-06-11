/// Daily practice drill shown on home after activation.
abstract final class DailyDrillConstants {
  DailyDrillConstants._();

  static const analyticsKey = 'daily_drill';
  static const defaultSubject = 'misc';
  static const questionCount = 10;

  /// Local hour (0–23) for the optional daily practice reminder.
  static const defaultReminderHour = 8;
}
