import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';

import '../../support/test_question_builder.dart';

/// Mirrors the rule used for Danger Zone review lists and session aggregates.
List<TestQuestion> filterDangerZoneQuestions(List<TestQuestion> questions) {
  return questions
      .where(
        (q) =>
            q.status == 'wrong' &&
            AnswerConfidence.isDangerouslyConfident(q.confidence),
      )
      .toList();
}

void main() {
  test('filter keeps only wrong + very sure / somewhat sure', () {
    final qs = [
      buildTestQuestion(
        uuid: '1',
        status: 'wrong',
        confidence: AnswerConfidence.verySure,
      ),
      buildTestQuestion(
        uuid: '2',
        status: 'wrong',
        confidence: AnswerConfidence.somewhatSure,
      ),
      buildTestQuestion(
        uuid: '3',
        status: 'wrong',
        confidence: AnswerConfidence.guessing,
      ),
      buildTestQuestion(uuid: '4', status: 'wrong', confidence: null),
      buildTestQuestion(
        uuid: '5',
        status: 'correct',
        confidence: AnswerConfidence.verySure,
      ),
    ];

    final filtered = filterDangerZoneQuestions(qs);
    expect(filtered.map((e) => e.uuid).toList(), ['1', '2']);
  });
}
