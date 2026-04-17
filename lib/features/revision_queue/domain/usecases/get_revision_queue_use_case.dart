import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';
import 'package:upsc_wars/core/domain/entities/weak_concept_group.dart';
import 'package:upsc_wars/core/domain/entities/trap_pattern_group.dart';
import '../repositories/revision_repository.dart';

class GetRevisionQueueUseCase {
  const GetRevisionQueueUseCase(this._repository);
  final RevisionRepository _repository;

  Future<List<RevisionQueueItem>> execute() => _repository.getActiveRevisionQueueItems();
  Future<int> count() => _repository.getActiveRevisionQueueCount();
  Future<List<String>> subjects({int limit = 3}) => _repository.getActiveRevisionSubjectSlugs(limit: limit);

  Future<List<WeakSubTopicGroup>> subTopicGroups() => _repository.getWeakSubTopicGroups();
  Future<List<TrapPatternGroup>> trapGroups() => _repository.getWeakTrapGroups();
  Future<int> uniqueSubTopicCount() => _repository.getUniqueSubTopicCount();
  Future<int> uniqueTrapTypeCount() => _repository.getUniqueTrapTypeCount();
}
