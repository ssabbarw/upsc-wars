import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:upsc_wars/core/database/question_db.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/bookmark_item.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/features/bookmarks/domain/repositories/bookmarks_repository.dart';

class BookmarksRepositoryImpl implements BookmarksRepository {
  const BookmarksRepositoryImpl({required UserDatabase userDb, required QuestionDb questionDb})
      : _userDb = userDb,
        _questionDb = questionDb;
  final UserDatabase _userDb;
  final QuestionDb _questionDb;
  static const _uuid = Uuid();

  @override
  Future<List<BookmarkItem>> getBookmarks() async {
    final rows = await _userDb.bookmarksDao.getAllBookmarksOrderedByCreatedAtDesc();
    final out = <BookmarkItem>[];
    for (final b in rows) {
      final q = (await _questionDb.getQuestionsByUuids([b.questionUuid])).firstOrNull;
      final tr = await _questionDb.getQuestionTranslation(b.questionUuid, 'en');
      if (q == null || tr == null) continue;
      out.add(BookmarkItem(
        id: b.id,
        questionUuid: b.questionUuid,
        createdAt: b.createdAt,
        note: b.note,
        subjectSlug: q.subjectSlug,
        topicSlug: q.topicSlug,
        questionStem: QuestionDisplayTextParser.parse(tr.displayText).stem,
      ));
    }
    return out;
  }

  @override
  Future<void> addBookmark(String questionUuid, {String? note}) async {
    final existing = await _userDb.bookmarksDao.getBookmarkByQuestionUuid(questionUuid);
    if (existing == null) {
      await _userDb.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: _uuid.v4(),
          questionUuid: questionUuid,
          createdAt: DateTime.now(),
          note: Value(note),
        ),
      );
    }
    await _userDb.revisionQueueDao.insertOrUpdateRevisionItem(
      id: _uuid.v4(),
      questionUuid: questionUuid,
      addedAt: DateTime.now(),
      reason: 'bookmarked',
    );
  }

  @override
  Future<void> removeBookmark(String questionUuid) => _userDb.bookmarksDao.deleteBookmarkByQuestionUuid(questionUuid);

  @override
  Future<bool> isBookmarked(String questionUuid) => _userDb.bookmarksDao.isQuestionBookmarked(questionUuid);

  @override
  Future<int> count() async => (await _userDb.bookmarksDao.getAllBookmarksOrderedByCreatedAtDesc()).length;
}
