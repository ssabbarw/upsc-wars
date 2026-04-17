import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';
import 'package:upsc_wars/core/domain/entities/weak_concept_group.dart';
import 'package:upsc_wars/core/domain/entities/trap_pattern_group.dart';

abstract class RevisionRepository {
  Future<List<RevisionQueueItem>> getActiveRevisionQueueItems();
  Future<int> getActiveRevisionQueueCount();
  Future<List<String>> getActiveRevisionSubjectSlugs({int limit = 3});
  Future<void> updateRevisionQueueProgress(String questionUuid);

  Future<List<WeakSubTopicGroup>> getWeakSubTopicGroups();
  Future<List<TrapPatternGroup>> getWeakTrapGroups();
  Future<int> getUniqueSubTopicCount();
  Future<int> getUniqueTrapTypeCount();
}
