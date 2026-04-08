import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';
import '../repositories/revision_repository.dart';

class GetRevisionQueueUseCase {
  const GetRevisionQueueUseCase(this._repository);
  final RevisionRepository _repository;

  Future<List<RevisionQueueItem>> execute() => _repository.getActiveRevisionQueueItems();
  Future<int> count() => _repository.getActiveRevisionQueueCount();
  Future<List<String>> subjects({int limit = 3}) => _repository.getActiveRevisionSubjectSlugs(limit: limit);
}
