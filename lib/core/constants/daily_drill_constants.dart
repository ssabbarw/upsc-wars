/// Daily practice drill shown on home after activation.
abstract final class DailyDrillConstants {
  DailyDrillConstants._();

  static const analyticsKey = 'daily_drill';
  static const defaultSubject = 'misc';
  static const questionCount = 10;

  /// Local hour (0–23) for the Daily Drill reminder.
  ///
  /// 7 PM: after work/college, before the 9 PM Daily Battle. Morning is left
  /// for the CA paper (7 AM) when that flag is on.
  static const defaultReminderHour = 19;

  /// Fresh-question subject when the revision queue is empty.
  static const weekdaySubjects = [
    'Polity',
    'Geography',
    'Economy',
    'Modern History',
    'Environment',
    'Ancient History',
    defaultSubject,
  ];

  static String subjectForHubDay(DateTime hubDate) =>
      weekdaySubjects[hubDate.weekday - 1];
}
