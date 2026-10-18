import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore paths and field names for global per-question analytics counters.
abstract final class QuestionStatsFirestore {
  static const collectionName = 'question_stats';
  static const syncLogCollectionName = 'question_stats_sync_log';

  static DocumentReference<Map<String, dynamic>> doc(String questionId) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(questionId);
  }

  static const totalAttempts = 'total_attempts';
  static const correctCount = 'correct_count';
  static const incorrectCount = 'incorrect_count';
  static const optionACount = 'option_a_count';
  static const optionBCount = 'option_b_count';
  static const optionCCount = 'option_c_count';
  static const optionDCount = 'option_d_count';
  static const totalTimeSeconds = 'total_time_seconds';
  static const sureAttemptCount = 'sure_attempt_count';
  static const sureWrongCount = 'sure_wrong_count';
  static const skippedCount = 'skipped_count';
  static const firstAttemptCorrectCount = 'first_attempt_correct_count';
  static const reportCount = 'report_count';
  static const bookmarkedCount = 'bookmarked_count';
  static const updatedAt = 'updated_at';
}
