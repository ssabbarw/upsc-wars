import '../repositories/bookmarks_repository.dart';

class AddBookmarkUseCase {
  const AddBookmarkUseCase(this._repository);
  final BookmarksRepository _repository;

  Future<void> execute(String questionUuid, {String? note}) => _repository.addBookmark(questionUuid, note: note);
}
