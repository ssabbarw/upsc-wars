import '../repositories/revision_repository.dart';

class UpdateRevisionQueueProgressUseCase {
  const UpdateRevisionQueueProgressUseCase(this._repository);
  final RevisionRepository _repository;

  Future<void> execute(String questionUuid) =>
      _repository.updateRevisionQueueProgress(questionUuid);
}
