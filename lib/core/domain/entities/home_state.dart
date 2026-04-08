import 'session_summary.dart';

class HomeState {
  const HomeState({
    required this.streakCount,
    required this.longestStreak,
    required this.dailyGoalTarget,
    required this.dailyGoalProgress,
    required this.revisionQueueCount,
    required this.bookmarkCount,
    required this.revisionSubjects,
    required this.lastSession,
  });

  final int streakCount;
  final int longestStreak;
  final int dailyGoalTarget;
  final int dailyGoalProgress;
  final int revisionQueueCount;
  final int bookmarkCount;
  final List<String> revisionSubjects;
  final SessionSummary? lastSession;
}
