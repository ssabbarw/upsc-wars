import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/domain/entities/session_summary.dart';

abstract class SessionHistoryRepository {
  Future<SessionResult> getSessionResult(String sessionId);
  Future<List<SessionSummary>> getSessionList({String? subject, String? mode});

  /// Completed sessions for [subject], newest first (paginated).
  Future<List<SessionSummary>> getCompletedSessionSummariesPage({
    required String subject,
    required int limit,
    required int offset,
  });

  Future<int> countCompletedSessionsForSubject(String subject);

  Future<int> getDailyProgressCount(DateTime date);
}
