import 'package:upsc_wars/core/analytics/question_attempt_analytics_input.dart';

import '../repositories/test_engine_repository.dart';

class UpdateQuestionAttemptUseCase {
  const UpdateQuestionAttemptUseCase(this._repository);

  final TestEngineRepository _repository;

  Future<bool> execute({
    required String sessionId,
    required String questionUuid,
    required String selectedOption,
    String? confidence,
    QuestionAttemptAnalyticsInput? analytics,
  }) {
    return _repository.updateQuestionAttempt(
      sessionId: sessionId,
      questionUuid: questionUuid,
      selectedOption: selectedOption,
      confidence: confidence,
      analytics: analytics,
    );
  }
}
