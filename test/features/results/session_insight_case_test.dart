import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/features/home/providers/home_activation_provider.dart';
import 'package:upsc_wars/features/results/domain/session_insight_case.dart';

SessionResult _result({
  int correct = 0,
  int wrong = 0,
  int? questionCount,
  int unattempted = 0,
  int sureTotal = 0,
  int sureCorrect = 0,
  int eduTotal = 0,
  int eduCorrect = 0,
  int pureTotal = 0,
  int pureCorrect = 0,
  String mode = 'exam',
}) {
  final total = questionCount ?? (correct + wrong + unattempted);
  return SessionResult(
    sessionId: 's1',
    subject: 'polity',
    topic: null,
    subTopic: null,
    mode: mode,
    createdAt: DateTime.utc(2026, 1, 1),
    completedAt: DateTime.utc(2026, 1, 1),
    timeLimitSecs: 600,
    questionCount: total,
    correct: correct,
    wrong: wrong,
    unattempted: unattempted,
    timedOut: 0,
    accuracy: 0,
    accuracyTier: 'low',
    netScore: 0,
    avgTimeSpentSecs: 2,
    totalTimeSpentSecs: 20,
    language: 'en',
    confidenceSureTotal: sureTotal,
    confidenceSureCorrect: sureCorrect,
    confidenceIntelligentTotal: eduTotal,
    confidenceIntelligentCorrect: eduCorrect,
    confidencePureTotal: pureTotal,
    confidencePureCorrect: pureCorrect,
  );
}

void main() {
  group('classifySessionInsight', () {
    test('F when confidence tracking disabled', () {
      final r = _result(wrong: 5, sureTotal: 5);
      expect(
        classifySessionInsight(result: r, confidenceTrackingEnabled: false),
        SessionInsightCase.fLockedSettings,
      );
    });

    test('no attempts returns fNoAttempts', () {
      final r = _result(correct: 0, wrong: 0);
      expect(
        classifySessionInsight(result: r, confidenceTrackingEnabled: true),
        SessionInsightCase.fNoAttempts,
      );
    });

    test('F when exam with low coverage', () {
      final r = _result(correct: 1, wrong: 5, sureTotal: 1, sureCorrect: 1);
      expect(
        classifySessionInsight(result: r, confidenceTrackingEnabled: true),
        SessionInsightCase.fLockedSkipped,
      );
    });

    test('C when both sure and edu wrong', () {
      final r = _result(wrong: 3, sureTotal: 2, eduTotal: 1);
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.c,
      );
    });

    test('A when sure wrong only', () {
      final r = _result(wrong: 2, sureTotal: 2, pureTotal: 1, pureCorrect: 0);
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.a,
      );
    });

    test('B when edu wrong only', () {
      final r = _result(wrong: 2, eduTotal: 2);
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.b,
      );
    });

    test('D when pure guess wrong only', () {
      final r = _result(wrong: 3, pureTotal: 3);
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.d,
      );
    });

    test('E when no wrong answers and test substantially complete', () {
      final r = _result(correct: 5, sureTotal: 5, sureCorrect: 5);
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.e,
      );
    });

    test('G when no wrong answers but mostly unattempted', () {
      final r = _result(
        correct: 1,
        unattempted: 10,
        sureTotal: 1,
        sureCorrect: 1,
      );
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.gIncomplete,
      );
    });

    test('G when no wrong answers but below completion threshold', () {
      final r = _result(
        correct: 2,
        unattempted: 8,
        sureTotal: 2,
        sureCorrect: 2,
      );
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.gIncomplete,
      );
    });

    test('E when no wrong answers and most questions attempted', () {
      final r = _result(
        correct: 6,
        unattempted: 5,
        sureTotal: 6,
        sureCorrect: 6,
      );
      expect(
        classifySessionInsight(
          result: r,
          confidenceTrackingEnabled: true,
          confidenceCoverage: 1.0,
        ),
        SessionInsightCase.e,
      );
    });
  });

  group('sessionIsCompleteEnoughForExcellent', () {
    test('false when only one of many attempted', () {
      final r = _result(correct: 1, unattempted: 10);
      expect(sessionIsCompleteEnoughForExcellent(r), isFalse);
    });

    test('true when every question attempted', () {
      final r = _result(correct: 5);
      expect(sessionIsCompleteEnoughForExcellent(r), isTrue);
    });

    test('true when at least half attempted on longer test', () {
      final r = _result(correct: 6, unattempted: 5);
      expect(sessionIsCompleteEnoughForExcellent(r), isTrue);
    });
  });

  group('derived counts', () {
    test('sure and edu wrong counts', () {
      final r = _result(
        sureTotal: 4,
        sureCorrect: 2,
        eduTotal: 3,
        eduCorrect: 1,
      );
      expect(sessionSureWrongCount(r), 2);
      expect(sessionEduWrongCount(r), 2);
      expect(sessionTierMarksLost(2), closeTo(1.32, 0.001));
    });
  });

  group('consecutiveActivationSessionDays', () {
    test('empty returns 0', () {
      expect(consecutiveActivationSessionDays([]), 0);
    });

    test('counts trailing streak', () {
      expect(
        consecutiveActivationSessionDays([
          '2026-06-01',
          '2026-06-02',
          '2026-06-03',
        ]),
        3,
      );
    });

    test('breaks on gap', () {
      expect(
        consecutiveActivationSessionDays([
          '2026-06-01',
          '2026-06-03',
          '2026-06-04',
        ]),
        2,
      );
    });
  });
}
