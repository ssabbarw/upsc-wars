import 'package:upsc_wars/core/domain/entities/bookmark_item.dart';

abstract class BookmarksRepository {
  Future<List<BookmarkItem>> getBookmarks();
  Future<void> addBookmark(String questionUuid, {String? note});
  Future<void> removeBookmark(String questionUuid);
  Future<bool> isBookmarked(String questionUuid);
  Future<int> count();
}
