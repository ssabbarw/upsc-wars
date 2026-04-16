import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/domain/entities/session_summary.dart';

abstract class SessionHistoryRepository {
  Future<SessionResult> getSessionResult(String sessionId);
  Future<List<SessionSummary>> getSessionList({String? subject, String? mode});
  Future<int> getDailyProgressCount(DateTime date);
}
