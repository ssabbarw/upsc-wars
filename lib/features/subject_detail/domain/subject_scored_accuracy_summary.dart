/// All-time scored stats for one subject (from local attempts).
class SubjectScoredAccuracySummary {
  const SubjectScoredAccuracySummary({
    required this.scoredAttempted,
    required this.scoredCorrect,
    required this.uniqueQuestionsAttempted,
    required this.sureTotal,
    required this.sureWrong,
    required this.educatedGuessTotal,
    required this.educatedGuessWrong,
  });

  /// Answered questions with a known correct/wrong outcome.
  final int scoredAttempted;
  final int scoredCorrect;

  /// Distinct questions with at least one scored attempt in this subject.
  final int uniqueQuestionsAttempted;

  /// Attempts where confidence was Sure (`very_sure` in the DB).
  final int sureTotal;
  final int sureWrong;

  /// Attempts where confidence was Educated guess (`somewhat_sure` in the DB).
  final int educatedGuessTotal;
  final int educatedGuessWrong;

  double? get accuracyPercent =>
      scoredAttempted > 0 ? (100 * scoredCorrect / scoredAttempted) : null;

  /// Share of Sure-marked attempts that were wrong (0–100), or null if none.
  double? get wrongWhenSurePercent =>
      sureTotal > 0 ? (100 * sureWrong / sureTotal) : null;

  /// Share of Educated-guess attempts that were wrong (0–100), or null if none.
  double? get wrongWhenEducatedGuessPercent =>
      educatedGuessTotal > 0
          ? (100 * educatedGuessWrong / educatedGuessTotal)
          : null;
}
