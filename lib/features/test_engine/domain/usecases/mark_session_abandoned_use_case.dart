import '../repositories/test_engine_repository.dart';

class MarkSessionAbandonedUseCase {
  const MarkSessionAbandonedUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<void> execute(String sessionId) =>
      _repository.markSessionAbandoned(sessionId);
}
