import 'package:upsc_wars/core/analytics/question_attempt_analytics_input.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';

abstract class TestEngineRepository {
  Future<ActiveSession> loadSession(String sessionId);

  /// Loads a single catalog question as [TestQuestion] (no session row).
  /// Returns null if the UUID is missing locally.
  Future<TestQuestion?> loadStandaloneQuestionByUuid(String uuid);

  Future<int> countScoredAttempts();

  Future<Set<String>> fetchWeakTopicKeys(
    List<({String subject, String topic})> pairs,
  );

  Future<bool> updateQuestionAttempt({
    required String sessionId,
    required String questionUuid,
    required String selectedOption,
    String? confidence,
    QuestionAttemptAnalyticsInput? analytics,
  });

  /// Updates only `confidence` for an already scored attempt (exam optional slider).
  Future<void> updateAttemptConfidenceOnly({
    required String sessionId,
    required String questionUuid,
    String? confidence,
  });

  Future<void> updateQuestionTime({
    required String sessionId,
    required String questionUuid,
    required int timeSpentSecs,
  });

  Future<void> flagQuestion({
    required String sessionId,
    required String questionUuid,
    required bool flagged,
  });

  Future<String> submitSession(String sessionId);

  Future<void> handleTimedOutQuestion({
    required String sessionId,
    required String questionUuid,
  });

  Future<void> markSessionAbandoned(String sessionId);

  /// Permanently deletes an in-progress session and its attempts.
  /// Used when the user explicitly chooses to discard progress.
  Future<void> discardSession(
    String sessionId, {
    bool userInitiatedQuit = false,
  });

  Future<bool> isBookmarked(String questionUuid);
  Future<void> addBookmark(String questionUuid);
  Future<void> removeBookmark(String questionUuid);

  /// Persists approximate remaining time for timed exam resume (every ~10s while active).
  Future<void> saveExamRemainingSeconds({
    required String sessionId,
    required int remainingSecs,
  });
}
