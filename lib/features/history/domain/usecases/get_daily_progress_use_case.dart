import '../repositories/session_history_repository.dart';

class GetDailyProgressUseCase {
  const GetDailyProgressUseCase(this._repository);
  final SessionHistoryRepository _repository;
  Future<int> execute(DateTime date) => _repository.getDailyProgressCount(date);
}
