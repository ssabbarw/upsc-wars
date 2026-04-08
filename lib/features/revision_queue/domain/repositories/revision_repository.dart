import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';

abstract class RevisionRepository {
  Future<List<RevisionQueueItem>> getActiveRevisionQueueItems();
  Future<int> getActiveRevisionQueueCount();
  Future<List<String>> getActiveRevisionSubjectSlugs({int limit = 3});
  Future<void> updateRevisionQueueProgress(String questionUuid);
}
