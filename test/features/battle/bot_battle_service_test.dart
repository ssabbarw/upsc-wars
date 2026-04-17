import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/features/battle/domain/services/bot_battle_service.dart';

void main() {
  group('BotBattleService', () {
    test('returns deterministic plan for same inputs', () {
      const service = BotBattleService();
      final question = _question('q1', 'a');

      final first = service.buildPlan(
        sessionId: 'session-1',
        questionIndex: 0,
        question: question,
      );
      final second = service.buildPlan(
        sessionId: 'session-1',
        questionIndex: 0,
        question: question,
      );

      expect(first.selectedOption, second.selectedOption);
      expect(first.delay, second.delay);
    });

    test('always answers with one of four options', () {
      const service = BotBattleService();
      final plan = service.buildPlan(
        sessionId: 's',
        questionIndex: 2,
        question: _question('q2', 'c'),
      );
      expect(['a', 'b', 'c', 'd'], contains(plan.selectedOption));
      expect(plan.delay.inMilliseconds, greaterThan(0));
    });

    test('delay is between 5 and 100 seconds inclusive', () {
      const service = BotBattleService();
      for (var i = 0; i < 80; i++) {
        final plan = service.buildPlan(
          sessionId: 'session-$i',
          questionIndex: i % 5,
          question: _question('q$i', 'b'),
        );
        expect(
          plan.delay,
          greaterThanOrEqualTo(const Duration(seconds: 5)),
        );
        expect(
          plan.delay,
          lessThanOrEqualTo(const Duration(seconds: 100)),
        );
      }
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
