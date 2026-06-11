import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/user_db.dart';
import 'question_stats_firestore.dart';

/// In-memory increments for one question before a batched Firestore write.
class QuestionStatsDelta {
  QuestionStatsDelta({required this.questionId});

  final String questionId;
  int totalAttempts = 0;
  int correctCount = 0;
  int incorrectCount = 0;
  int optionACount = 0;
  int optionBCount = 0;
  int optionCCount = 0;
  int optionDCount = 0;
  int totalTimeSeconds = 0;
  int sureAttemptCount = 0;
  int sureWrongCount = 0;
  int skippedCount = 0;
  int firstAttemptCorrectCount = 0;

  void absorbRecord({
    required QuestionAttemptRecord record,
    required bool isFirstScoredAttempt,
  }) {
    if (record.skipped) {
      skippedCount++;
      return;
    }

    totalAttempts++;
    final time = record.timeTakenSeconds ?? 0;
    totalTimeSeconds += time;

    if (record.isSure) {
      sureAttemptCount++;
      if (record.isCorrect == false) {
        sureWrongCount++;
      }
    }

    final selected = record.selectedOption?.toLowerCase();
    switch (selected) {
      case 'a':
        optionACount++;
      case 'b':
        optionBCount++;
      case 'c':
        optionCCount++;
      case 'd':
        optionDCount++;
    }

    if (record.isCorrect == true) {
      correctCount++;
      if (isFirstScoredAttempt) {
        firstAttemptCorrectCount++;
      }
    } else if (record.isCorrect == false) {
      incorrectCount++;
    }
  }

  Map<String, FieldValue> toFirestoreIncrements() {
    final out = <String, FieldValue>{
      QuestionStatsFirestore.updatedAt: FieldValue.serverTimestamp(),
    };
    void add(String key, int delta) {
      if (delta != 0) out[key] = FieldValue.increment(delta);
    }

    add(QuestionStatsFirestore.totalAttempts, totalAttempts);
    add(QuestionStatsFirestore.correctCount, correctCount);
    add(QuestionStatsFirestore.incorrectCount, incorrectCount);
    add(QuestionStatsFirestore.optionACount, optionACount);
    add(QuestionStatsFirestore.optionBCount, optionBCount);
    add(QuestionStatsFirestore.optionCCount, optionCCount);
    add(QuestionStatsFirestore.optionDCount, optionDCount);
    add(QuestionStatsFirestore.totalTimeSeconds, totalTimeSeconds);
    add(QuestionStatsFirestore.sureAttemptCount, sureAttemptCount);
    add(QuestionStatsFirestore.sureWrongCount, sureWrongCount);
    add(QuestionStatsFirestore.skippedCount, skippedCount);
    add(
      QuestionStatsFirestore.firstAttemptCorrectCount,
      firstAttemptCorrectCount,
    );
    return out;
  }
}
