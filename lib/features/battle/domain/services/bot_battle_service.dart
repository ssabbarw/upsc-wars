import 'dart:math';

import 'package:upsc_wars/core/domain/entities/test_question.dart';

class BotAnswerPlan {
  const BotAnswerPlan({required this.selectedOption, required this.delay});

  final String selectedOption;
  final Duration delay;
}

class BotBattleService {
  const BotBattleService();

  BotAnswerPlan buildPlan({
    required String sessionId,
    required int questionIndex,
    required TestQuestion question,
  }) {
    final seed = Object.hash(sessionId, question.uuid, questionIndex);
    final rng = Random(seed);
    // Human-like pacing: 5–100 seconds before answering (per battle / question).
    final delaySecs = 5 + rng.nextInt(96);
    final delay = Duration(seconds: delaySecs);
    final accuracyRoll = rng.nextDouble();
    final shouldBeCorrect = accuracyRoll < 0.62;
    final correct = question.correctOption.toLowerCase();

    if (shouldBeCorrect) {
      return BotAnswerPlan(selectedOption: correct, delay: delay);
    }

    const options = ['a', 'b', 'c', 'd'];
    final wrong = options.where((o) => o != correct).toList();
    return BotAnswerPlan(
      selectedOption: wrong[rng.nextInt(wrong.length)],
      delay: delay,
    );
  }
}
