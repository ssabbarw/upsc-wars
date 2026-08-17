/// Daily practice drill shown on home after activation.
abstract final class DailyDrillConstants {
  DailyDrillConstants._();

  static const analyticsKey = 'daily_drill';
  static const defaultSubject = 'misc';
  static const questionCount = 10;

  /// Local hour (0–23) for the drill reminder.
  ///
  /// Mid-afternoon on purpose: the morning belongs to the current-affairs paper
  /// quiz, and this only fires on days where nothing has been done yet.
  static const defaultReminderHour = 15;
}
