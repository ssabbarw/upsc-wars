import 'package:upsc_wars/core/domain/entities/session_summary.dart';
import '../repositories/session_history_repository.dart';

class GetSessionListUseCase {
  const GetSessionListUseCase(this._repository);
  final SessionHistoryRepository _repository;
  Future<List<SessionSummary>> execute({String? subjectSlug, String? mode}) =>
      _repository.getSessionList(subjectSlug: subjectSlug, mode: mode);
}
