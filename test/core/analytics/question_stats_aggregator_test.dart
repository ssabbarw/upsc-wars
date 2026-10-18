import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/analytics/question_stats_aggregator.dart';
import 'package:upsc_wars/core/analytics/question_stats_derived.dart';
import 'package:upsc_wars/core/analytics/question_stats_firestore.dart';
import 'package:upsc_wars/core/database/user_db.dart';

QuestionAttemptRecord _record({
  required String questionId,
  String? selectedOption,
  bool? isCorrect,
  int? timeTakenSeconds,
  bool isSure = false,
  bool skipped = false,
}) {
  return QuestionAttemptRecord(
    id: 'r1',
    sessionId: 's1',
    questionId: questionId,
    selectedOption: selectedOption,
    isCorrect: isCorrect,
    timeTakenSeconds: timeTakenSeconds,
    isSure: isSure,
    skipped: skipped,
    attemptedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  test('QuestionStatsDelta aggregates scored and skipped attempts', () {
    final delta = QuestionStatsDelta(questionId: 'q1')
      ..absorbRecord(
        record: _record(
          questionId: 'q1',
          selectedOption: 'b',
          isCorrect: false,
          timeTakenSeconds: 42,
          isSure: true,
        ),
        isFirstScoredAttempt: true,
      )
      ..absorbRecord(
        record: _record(questionId: 'q1', skipped: true),
        isFirstScoredAttempt: false,
      );

    expect(delta.totalAttempts, 1);
    expect(delta.incorrectCount, 1);
    expect(delta.optionBCount, 1);
    expect(delta.totalTimeSeconds, 42);
    expect(delta.sureAttemptCount, 1);
    expect(delta.sureWrongCount, 1);
    expect(delta.skippedCount, 1);
    expect(delta.firstAttemptCorrectCount, 0);

    final increments = delta.toFirestoreIncrements();
    expect(
      increments.containsKey(QuestionStatsFirestore.totalAttempts),
      isTrue,
    );
    expect(increments.containsKey(QuestionStatsFirestore.updatedAt), isTrue);
  });

  test('first_attempt_correct_count only on first correct attempt', () {
    final delta = QuestionStatsDelta(questionId: 'q1')
      ..absorbRecord(
        record: _record(
          questionId: 'q1',
          selectedOption: 'a',
          isCorrect: true,
          timeTakenSeconds: 10,
        ),
        isFirstScoredAttempt: true,
      );

    expect(delta.firstAttemptCorrectCount, 1);
    expect(delta.correctCount, 1);
  });

  test('QuestionStatsDerived computes metrics from counters', () {
    expect(
      QuestionStatsDerived.accuracyPercent(totalAttempts: 10, correctCount: 7),
      70.0,
    );
    expect(
      QuestionStatsDerived.averageTimeSeconds(
        totalAttempts: 4,
        totalTimeSeconds: 100,
      ),
      25.0,
    );
    expect(
      QuestionStatsDerived.sureWrongRate(
        sureAttemptCount: 5,
        sureWrongCount: 2,
      ),
      0.4,
    );
    final distractors = QuestionStatsDerived.distractorEffectiveness(
      incorrectCount: 10,
      optionACount: 1,
      optionBCount: 4,
      optionCCount: 3,
      optionDCount: 2,
      correctOption: 'a',
    );
    expect(distractors, isNotNull);
    expect(distractors!['b'], 0.4);
  });
}
