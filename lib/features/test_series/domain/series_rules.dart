/// Numbers quoted in user-facing copy (paywall, intro, hints).
///
/// Keep these in one place and pass them into the localized strings, so a
/// rule change does not leave the English and Hindi texts stale.
abstract final class SeriesRules {
  /// Questions in a subject (static) test.
  static const staticTestQuestions = 50;

  /// Share of PYQs inside a subject test.
  static const staticTestPyqPercent = 10;

  /// Questions in a full-length mock.
  static const fltQuestions = 100;

  /// Duration of a full-length mock.
  static const fltHours = 2;

  /// A topic counts as a safe area at this accuracy…
  static const safeAccuracyPercent = 80;

  /// …over at least this many answered questions.
  static const safeMinQuestions = 4;
}
