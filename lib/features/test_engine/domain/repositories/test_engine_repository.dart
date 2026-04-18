import 'package:upsc_wars/core/analytics/question_attempt_analytics_input.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';

abstract class TestEngineRepository {
  Future<ActiveSession> loadSession(String sessionId);

  Future<bool> updateQuestionAttempt({
    required String sessionId,
    required String questionUuid,
    required String selectedOption,
    QuestionAttemptAnalyticsInput? analytics,
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

  Future<bool> isBookmarked(String questionUuid);
  Future<void> addBookmark(String questionUuid);
  Future<void> removeBookmark(String questionUuid);

  /// Persists approximate remaining time for timed exam resume (every ~10s while active).
  Future<void> saveExamRemainingSeconds({
    required String sessionId,
    required int remainingSecs,
  });
}
