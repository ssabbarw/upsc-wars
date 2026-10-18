import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/domain/repositories/create_session_repository.dart';

class CreateSessionUseCase {
  CreateSessionUseCase(this._repository);

  final CreateSessionRepository _repository;

  Future<String> execute(SessionConfig config) =>
      _repository.createSession(config);

  Future<void> importSharedBattle({
    required String sessionId,
    required SessionConfig config,
  }) => _repository.importSessionWithFixedId(
    sessionId: sessionId,
    config: config,
  );
}
