import 'package:upsc_wars/core/domain/entities/session_result.dart';
import '../repositories/session_history_repository.dart';

class GetSessionResultUseCase {
  const GetSessionResultUseCase(this._repository);
  final SessionHistoryRepository _repository;
  Future<SessionResult> execute(String sessionId) =>
      _repository.getSessionResult(sessionId);
}
