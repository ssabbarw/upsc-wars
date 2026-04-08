import '../repositories/test_engine_repository.dart';

class HandleTimedOutQuestionUseCase {
  const HandleTimedOutQuestionUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<void> execute({
    required String sessionId,
    required String questionUuid,
  }) {
    return _repository.handleTimedOutQuestion(
      sessionId: sessionId,
      questionUuid: questionUuid,
    );
  }
}
