import '../repositories/bookmarks_repository.dart';

class RemoveBookmarkUseCase {
  const RemoveBookmarkUseCase(this._repository);
  final BookmarksRepository _repository;

  Future<void> execute(String questionUuid) =>
      _repository.removeBookmark(questionUuid);
}
