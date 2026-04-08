import '../repositories/test_engine_repository.dart';

class SubmitSessionUseCase {
  const SubmitSessionUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<String> execute(String sessionId) => _repository.submitSession(sessionId);
}
