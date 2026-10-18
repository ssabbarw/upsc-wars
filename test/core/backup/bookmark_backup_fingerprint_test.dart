import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/backup/bookmark_backup_service.dart';
import 'package:upsc_wars/core/database/user_db.dart';

/// The upload decision rests on this fingerprint: it must ignore row order,
/// but change on add, remove and note edits.
void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> add(String id, String uuid, int ms, {String? note}) =>
      db.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: id,
          questionUuid: uuid,
          createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
          userNote: Value(note),
        ),
      );

  Future<String> fp() async => BookmarkBackupService.fingerprint(
    await db.bookmarksDao.getAllBookmarksOrderedByCreatedAtDesc(),
  );

  test(
    'fingerprint is stable, order-independent and change-sensitive',
    () async {
      final empty = await fp();
      await add('1', 'q1', 1000);
      final one = await fp();
      expect(one, isNot(empty));

      await add('2', 'q2', 2000, note: 'remember');
      final two = await fp();
      expect(two, isNot(one));
      expect(await fp(), two); // stable

      // Same set inserted in a different order gives the same fingerprint.
      final other = UserDatabase(NativeDatabase.memory());
      await other.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: 'b',
          questionUuid: 'q2',
          createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
          userNote: const Value('remember'),
        ),
      );
      await other.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: 'a',
          questionUuid: 'q1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        ),
      );
      expect(
        BookmarkBackupService.fingerprint(
          await other.bookmarksDao.getAllBookmarksOrderedByCreatedAtDesc(),
        ),
        two,
      );
      await other.close();

      await db.bookmarksDao.deleteBookmarkByQuestionUuid('q2');
      expect(await fp(), one); // removal returns to the earlier state
    },
  );
}
