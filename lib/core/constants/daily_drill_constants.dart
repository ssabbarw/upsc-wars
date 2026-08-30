/// Daily practice drill shown on home after activation.
abstract final class DailyDrillConstants {
  DailyDrillConstants._();

  static const analyticsKey = 'daily_drill';
  static const defaultSubject = 'misc';
  static const questionCount = 10;

  /// Local hour (0–23) for the drill reminder.
  ///
  /// Mid-afternoon on purpose: the morning belongs to the current-affairs paper
  /// quiz. Only fires once that paper is revised and the revision queue is open.
  static const defaultReminderHour = 15;

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
