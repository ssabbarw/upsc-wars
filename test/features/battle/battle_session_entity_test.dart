import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_participant.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_session.dart';

void main() {
  test('BattleSession copyWith updates response maps', () {
    final session = BattleSession(
      id: 's1',
      baseSession: _activeSession(),
      player: const BattleParticipant(id: 'p1', displayName: 'You'),
      opponent: const BattleParticipant(
        id: 'opponent',
        displayName: 'Opponent',
      ),
      playerResponsesByQuestion: const {'q1': 'a'},
      opponentResponsesByQuestion: const {'q1': 'b'},
    );

    final updated = session.copyWith(
      playerResponsesByQuestion: const {'q1': 'c'},
    );

    expect(updated.playerResponsesByQuestion['q1'], 'c');
    expect(updated.opponentResponsesByQuestion['q1'], 'b');
  });
}

ActiveSession _activeSession() {
  return ActiveSession(
    id: 's1',
    mode: 'exam',
    subject: 'history',
    topic: null,
    subTopic: null,
    questionCount: 1,
    isTimed: true,
    timeLimitSecs: 72,
    status: 'active',
    language: 'en',
    questions: [_question()],
  );
}

TestQuestion _question() {
  return const TestQuestion(
    uuid: 'q1',
    subject: 'history',
    topic: 'general',
    negativeFraming: false,
    displayText: 'Q1',
    displayTextHi: 'Q1',
    optionA: 'A',
    optionAHi: 'A',
    optionB: 'B',
    optionBHi: 'B',
    optionC: 'C',
    optionCHi: 'C',
    optionD: 'D',
    optionDHi: 'D',
    correctOption: 'a',
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
    confidence: null,
    conceptAnchor: null,
    finalExplanation: null,
    finalExplanationHi: null,
    eliminationLogic: [],
    eliminationLogicHi: [],
    statementAnalysis: [],
    statementAnalysisHi: [],
    strongDistractor: null,
    strongDistractorHi: null,
    upscTrapExplanation: null,
    upscTrapExplanationHi: null,
    conceptsUsed: [],
  );
}
