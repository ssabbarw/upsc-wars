import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'user_database_provider.dart';

/// Live count of active (ungraduated) revision queue items.
/// Backed by a Drift SQL watch — auto-updates when the table changes.
final activeRevisionQueueCountProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return db.revisionQueueDao.watchActiveQueueCount();
});

/// Live count of bookmarked questions.
/// Backed by a Drift SQL watch — auto-updates when the table changes.
final bookmarkCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return db.bookmarksDao.watchBookmarkCount();
});
