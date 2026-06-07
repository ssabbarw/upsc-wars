import '../../../core/domain/entities/test_question.dart';

/// Sure-wrong and educated-guess-wrong questions from one session.
class MistakeReviewBundle {
  const MistakeReviewBundle({
    required this.sureWrong,
    required this.eduGuessWrong,
  });

  final List<TestQuestion> sureWrong;
  final List<TestQuestion> eduGuessWrong;

  int get total => sureWrong.length + eduGuessWrong.length;

  bool get hasSureWrong => sureWrong.isNotEmpty;

  bool get hasEduGuessWrong => eduGuessWrong.isNotEmpty;

  bool get hasBothTypes => hasSureWrong && hasEduGuessWrong;

  /// Review order: confident mistakes first, then educated guess.
  List<TestQuestion> get orderedQuestions => [...sureWrong, ...eduGuessWrong];
}
