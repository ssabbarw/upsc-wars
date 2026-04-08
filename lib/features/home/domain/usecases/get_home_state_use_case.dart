import 'package:upsc_wars/core/domain/entities/home_state.dart';
import 'package:upsc_wars/core/domain/entities/session_summary.dart';
import 'package:upsc_wars/features/bookmarks/domain/usecases/get_bookmarks_use_case.dart';
import 'package:upsc_wars/features/history/domain/usecases/get_daily_progress_use_case.dart';
import 'package:upsc_wars/features/history/domain/usecases/get_session_list_use_case.dart';
import 'package:upsc_wars/features/revision_queue/domain/usecases/get_revision_queue_use_case.dart';
import '../../../../core/providers/prefs_provider.dart';

class GetHomeStateUseCase {
  const GetHomeStateUseCase({required PrefsService prefs, required GetDailyProgressUseCase daily, required GetRevisionQueueUseCase revision, required GetBookmarksUseCase bookmarks, required GetSessionListUseCase sessions})
      : _prefs = prefs,
        _daily = daily,
        _revision = revision,
        _bookmarks = bookmarks,
        _sessions = sessions;
  final PrefsService _prefs;
  final GetDailyProgressUseCase _daily;
  final GetRevisionQueueUseCase _revision;
  final GetBookmarksUseCase _bookmarks;
  final GetSessionListUseCase _sessions;

  Future<HomeState> execute() async {
    final futures = await Future.wait([
      _daily.execute(DateTime.now()),
      _revision.count(),
      _bookmarks.count(),
      _revision.subjects(limit: 3),
      _sessions.execute(),
    ]);
    final sessionList = futures[4] as List<SessionSummary>;
    final inProgress =
        sessionList.where((e) => e.status == 'in_progress').firstOrNull;
    final lastCompleted =
        sessionList.where((e) => e.status == 'completed').firstOrNull;
    final lastSession = inProgress ?? lastCompleted;
    return HomeState(
      streakCount: _prefs.currentStreak,
      longestStreak: _prefs.longestStreak,
      dailyGoalTarget: _prefs.dailyGoal,
      dailyGoalProgress: futures[0] as int,
      revisionQueueCount: futures[1] as int,
      bookmarkCount: futures[2] as int,
      revisionSubjects: futures[3] as List<String>,
      lastSession: lastSession,
    );
  }
}
