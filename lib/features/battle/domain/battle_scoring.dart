import 'package:upsc_wars/core/domain/entities/test_question.dart';

class BattleScore {
  const BattleScore({
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

BattleScore calculateUpscBattleScore({
  required List<TestQuestion> questions,
  required Map<String, String> selectedOptionByQuestion,
}) {
  var correct = 0;
  var wrong = 0;
  var unanswered = 0;
  for (final q in questions) {
    final selected = selectedOptionByQuestion[q.uuid];
    if (selected == null || selected.isEmpty) {
      unanswered++;
      continue;
    }
    if (selected.toLowerCase() == q.correctOption.toLowerCase()) {
      correct++;
    } else {
      wrong++;
    }
  }
  return BattleScore(
    correct: correct,
    wrong: wrong,
    unanswered: unanswered,
    points: (correct * 2) - (wrong * 0.66),
  );
}
