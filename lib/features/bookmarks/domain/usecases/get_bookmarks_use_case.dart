import 'package:upsc_wars/core/domain/entities/bookmark_item.dart';
import '../repositories/bookmarks_repository.dart';

class GetBookmarksUseCase {
  const GetBookmarksUseCase(this._repository);
  final BookmarksRepository _repository;

  Future<List<BookmarkItem>> execute() => _repository.getBookmarks();
  Future<int> count() => _repository.count();
}
