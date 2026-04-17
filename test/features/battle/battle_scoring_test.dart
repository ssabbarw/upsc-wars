import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/features/battle/domain/battle_scoring.dart';

void main() {
  group('calculateUpscBattleScore', () {
    test('calculates correct wrong unanswered and points', () {
      final questions = [
        _question('q1', 'a'),
        _question('q2', 'b'),
        _question('q3', 'c'),
      ];
      final score = calculateUpscBattleScore(
        questions: questions,
        selectedOptionByQuestion: {'q1': 'a', 'q2': 'd'},
      );

      expect(score.correct, 1);
      expect(score.wrong, 1);
      expect(score.unanswered, 1);
      expect(score.points, closeTo(1.34, 0.001));
    });
  });
}

TestQuestion _question(String id, String correctOption) {
  return TestQuestion(
    uuid: id,
    displayText: 'question',
    displayTextHi: 'question',
    optionA: 'A',
    optionAHi: 'A',
    optionB: 'B',
    optionBHi: 'B',
    optionC: 'C',
    optionCHi: 'C',
    optionD: 'D',
    optionDHi: 'D',
    correctOption: correctOption,
    questionType: null,
    trapType: null,
    hasTable: false,
    tableData: null,
    tableDataHi: null,
    position: 0,
    selectedOption: null,
    status: 'unattempted',
    flagged: false,
    timeSpentSecs: null,
    conceptAnchor: null,
    finalExplanation: null,
    finalExplanationHi: null,
    eliminationLogic: const [],
    eliminationLogicHi: const [],
    statementAnalysis: const [],
    statementAnalysisHi: const [],
    strongDistractor: null,
    strongDistractorHi: null,
    upscTrapExplanation: null,
    upscTrapExplanationHi: null,
    conceptsUsed: const [],
  );
}
