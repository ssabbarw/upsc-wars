/// UPSC-style scoring for Daily CA ranks: +2 correct, −2/3 wrong, 0 unanswered.
/// Same formula as Daily Static Wars.
abstract final class DailyCaScoring {
  DailyCaScoring._();

  static const pointsCorrect = 2.0;
  static const pointsWrong = 2.0 / 3.0;

  static DailyCaScoreBreakdown score({
    required Map<String, String> selectedByUuid,
    required Map<String, String> correctByUuid,
  }) {
    var correct = 0;
    var wrong = 0;
    var unanswered = 0;

    for (final uuid in correctByUuid.keys) {
      final selected = selectedByUuid[uuid];
      if (selected == null || selected.trim().isEmpty) {
        unanswered++;
        continue;
      }
      final expected = correctByUuid[uuid]!.trim().toLowerCase();
      if (selected.trim().toLowerCase() == expected) {
        correct++;
      } else {
        wrong++;
      }
    }

    final points = (correct * pointsCorrect) - (wrong * pointsWrong);
    return DailyCaScoreBreakdown(
      correct: correct,
      wrong: wrong,
      unanswered: unanswered,
      points: double.parse(points.toStringAsFixed(2)),
    );
  }

  static double maxPoints(int questionCount) =>
      questionCount * pointsCorrect;
}

class DailyCaScoreBreakdown {
  const DailyCaScoreBreakdown({
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.points,
  });

  final int correct;
  final int wrong;
  final int unanswered;
  final double points;
}
