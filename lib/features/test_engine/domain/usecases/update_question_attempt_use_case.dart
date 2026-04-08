import '../repositories/test_engine_repository.dart';

class UpdateQuestionAttemptUseCase {
  const UpdateQuestionAttemptUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<bool> execute({
    required String sessionId,
    required String questionUuid,
    required String selectedOption,
  }) {
    return _repository.updateQuestionAttempt(
      sessionId: sessionId,
      questionUuid: questionUuid,
      selectedOption: selectedOption,
    );
  }
}
