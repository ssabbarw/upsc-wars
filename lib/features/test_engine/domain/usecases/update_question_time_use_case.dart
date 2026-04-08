import '../repositories/test_engine_repository.dart';

class UpdateQuestionTimeUseCase {
  const UpdateQuestionTimeUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<void> execute({
    required String sessionId,
    required String questionUuid,
    required int timeSpentSecs,
  }) {
    return _repository.updateQuestionTime(
      sessionId: sessionId,
      questionUuid: questionUuid,
      timeSpentSecs: timeSpentSecs,
    );
  }
}
