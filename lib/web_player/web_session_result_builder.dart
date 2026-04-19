import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';

/// In-memory attempt row for the web player (no Drift).
class WebPlayerAttemptSnapshot {
  const WebPlayerAttemptSnapshot({
    this.selectedOption,
    this.confidence,
    this.revealed = false,
    this.examAnswered = false,
  });

  final String? selectedOption;
  final String? confidence;
  final bool revealed;
  /// In exam mode: option + confidence locked for this question.
  final bool examAnswered;

  bool get scored {
    if (examAnswered && selectedOption != null) return true;
    if (revealed && selectedOption != null) return true;
    if (revealed && selectedOption == null) return true;
    return false;
  }
}

String tierFor(int attempted, double accuracy) {
  if (attempted == 0) return 'dash';
  if (attempted < 10) return 'muted';
  if (accuracy >= 70) return 'high';
  if (accuracy >= 55) return 'medium';
  return 'low';
}

/// Builds [SessionResult] from the current web run (stats only; no DB).
SessionResult buildWebPlayerSessionResult({
  required String shareId,
  required String subject,
  required String? topic,
  required String mode,
  required String language,
  required int? timeLimitSecs,
  required DateTime startedAt,
  required DateTime completedAt,
  required List<TestQuestion> questions,
  required Map<String, WebPlayerAttemptSnapshot> attempts,
}) {
  var correct = 0, wrong = 0, unattempted = 0, timedOut = 0;

  for (final q in questions) {
    final a = attempts[q.uuid];
    if (a == null) {
      unattempted++;
      continue;
    }
    if (mode == 'learning') {
      if (!a.revealed) {
        unattempted++;
        continue;
      }
      if (a.selectedOption == null) {
        timedOut++;
        continue;
      }
      if (a.selectedOption == q.correctOption.toLowerCase()) {
        correct++;
      } else {
        wrong++;
      }
    } else {
      if (!a.examAnswered || a.selectedOption == null) {
        unattempted++;
        continue;
      }
      if (a.selectedOption == q.correctOption.toLowerCase()) {
        correct++;
      } else {
        wrong++;
      }
    }
  }

  final attempted = correct + wrong;
  final accuracy = attempted == 0 ? 0.0 : (correct / attempted) * 100;

  var dangerZoneWrong = 0;
  for (final q in questions) {
    final a = attempts[q.uuid];
    if (a == null) continue;
    final wrongAns = a.selectedOption != null &&
        a.selectedOption != q.correctOption.toLowerCase();
    if (wrongAns && AnswerConfidence.isDangerouslyConfident(a.confidence)) {
      dangerZoneWrong++;
    }
  }
  final dangerMarks = dangerZoneWrong * 0.66;

  var sureT = 0, sureC = 0, intelT = 0, intelC = 0, pureT = 0, pureC = 0;
  for (final q in questions) {
    final a = attempts[q.uuid];
    if (a == null) continue;
    final scoredRow = mode == 'learning'
        ? a.revealed && a.selectedOption != null
        : a.examAnswered && a.selectedOption != null;
    if (!scoredRow) continue;
    final c = a.confidence;
    if (c == AnswerConfidence.verySure) {
      sureT++;
      if (a.selectedOption == q.correctOption.toLowerCase()) sureC++;
    } else if (c == AnswerConfidence.somewhatSure) {
      intelT++;
      if (a.selectedOption == q.correctOption.toLowerCase()) intelC++;
    } else if (c == AnswerConfidence.guessing) {
      pureT++;
      if (a.selectedOption == q.correctOption.toLowerCase()) pureC++;
    }
  }

  return SessionResult(
    sessionId: shareId,
    subject: subject,
    topic: topic,
    subTopic: null,
    mode: mode,
    createdAt: startedAt,
    completedAt: completedAt,
    timeLimitSecs: timeLimitSecs,
    questionCount: questions.length,
    correct: correct,
    wrong: wrong,
    unattempted: unattempted,
    timedOut: timedOut,
    accuracy: accuracy,
    accuracyTier: tierFor(attempted, accuracy),
    netScore: (correct * 2) - (wrong * 0.66),
    avgTimeSpentSecs: null,
    totalTimeSpentSecs: 0,
    language: language,
    graduatedCount: 0,
    dangerZoneWrongCount: dangerZoneWrong,
    dangerZoneMarksEstimate: dangerMarks,
    confidenceSureTotal: sureT,
    confidenceSureCorrect: sureC,
    confidenceIntelligentTotal: intelT,
    confidenceIntelligentCorrect: intelC,
    confidencePureTotal: pureT,
    confidencePureCorrect: pureC,
    analyticsFeatureKey: 'web_player_share',
  );
}
