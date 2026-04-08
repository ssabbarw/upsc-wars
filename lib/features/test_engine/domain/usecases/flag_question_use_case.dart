import '../repositories/test_engine_repository.dart';

class FlagQuestionUseCase {
  const FlagQuestionUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<void> execute({
    required String sessionId,
    required String questionUuid,
    required bool flagged,
  }) {
    return _repository.flagQuestion(
      sessionId: sessionId,
      questionUuid: questionUuid,
      flagged: flagged,
    );
  }
}
