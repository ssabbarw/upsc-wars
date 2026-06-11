/// Metric keys stored under `admin_dashboard/daily/{YYYY-MM-DD}` counters and
/// `admin_dashboard/daily/{YYYY-MM-DD}/users/{metric}__{uid}` presence docs.
abstract final class AdminDashboardMetrics {
  AdminDashboardMetrics._();

  static const newDownloads = 'new_downloads';
  static const onboardingCompletedUsers = 'onboarding_completed_users';
  static const firstDemoTestUsers = 'first_demo_test_users';
  static const firstTestUsers = 'first_test_users';
  static const testTakers = 'test_takers';
  static const firstMemoryGameUsers = 'first_memory_game_users';
  static const memoryGamePlays = 'memory_game_plays';
  static const battleUsers = 'battle_users';
  static const chatUsers = 'chat_users';

  static const allDailyCounters = <String>[
    newDownloads,
    onboardingCompletedUsers,
    firstDemoTestUsers,
    firstTestUsers,
    testTakers,
    firstMemoryGameUsers,
    memoryGamePlays,
    battleUsers,
    chatUsers,
  ];
}
