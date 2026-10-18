/// Derived metrics computed from aggregated Firestore counters (not stored).
abstract final class QuestionStatsDerived {
  static double? accuracyPercent({
    required int totalAttempts,
    required int correctCount,
  }) {
    if (totalAttempts <= 0) return null;
    return (correctCount / totalAttempts) * 100;
  }

  static double? averageTimeSeconds({
    required int totalAttempts,
    required int totalTimeSeconds,
  }) {
    if (totalAttempts <= 0) return null;
    return totalTimeSeconds / totalAttempts;
  }

  /// Higher values suggest easier questions (more correct attempts).
  static double? difficultyIndex({
    required int totalAttempts,
    required int correctCount,
  }) {
    final accuracy = accuracyPercent(
      totalAttempts: totalAttempts,
      correctCount: correctCount,
    );
    if (accuracy == null) return null;
    return accuracy / 100;
  }

  /// Share of wrong attempts that picked each distractor (0..1 per option).
  static Map<String, double>? distractorEffectiveness({
    required int incorrectCount,
    required int optionACount,
    required int optionBCount,
    required int optionCCount,
    required int optionDCount,
    required String correctOption,
  }) {
    if (incorrectCount <= 0) return null;
    final wrong = incorrectCount.toDouble();
    final counts = {
      'a': optionACount.toDouble(),
      'b': optionBCount.toDouble(),
      'c': optionCCount.toDouble(),
      'd': optionDCount.toDouble(),
    };
    counts.remove(correctOption.toLowerCase());
    return {for (final e in counts.entries) e.key: e.value / wrong};
  }

  static double? sureWrongRate({
    required int sureAttemptCount,
    required int sureWrongCount,
  }) {
    if (sureAttemptCount <= 0) return null;
    return sureWrongCount / sureAttemptCount;
  }
}
