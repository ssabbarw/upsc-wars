import 'package:upsc_wars/core/domain/entities/active_session.dart';
import '../repositories/test_engine_repository.dart';

class LoadSessionUseCase {
  const LoadSessionUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<ActiveSession> execute(String sessionId) =>
      _repository.loadSession(sessionId);
}
