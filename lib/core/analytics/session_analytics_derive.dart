/// Maps a persisted session row into stable analytics labels.
class SessionAnalyticsLabels {
  const SessionAnalyticsLabels({
    required this.featureName,
    required this.source,
  });

  final String featureName;
  final String source;
}

SessionAnalyticsLabels deriveSessionAnalyticsLabels({
  String? analyticsFeatureKey,
  required String subject,
}) {
  if (analyticsFeatureKey == 'mcq_battle') {
    return const SessionAnalyticsLabels(
      featureName: 'mcq_battle',
      source: 'test_series',
    );
  }
  if (analyticsFeatureKey == 'trap_awareness') {
    return const SessionAnalyticsLabels(
      featureName: 'trap_awareness',
      source: 'static_mcq',
    );
  }
  if (analyticsFeatureKey == 'insights_dashboard') {
    return const SessionAnalyticsLabels(
      featureName: 'insights_dashboard',
      source: 'static_mcq',
    );
  }
  if (analyticsFeatureKey == 'daily_drill') {
    return const SessionAnalyticsLabels(
      featureName: 'daily_drill',
      source: 'static_mcq',
    );
  }
  if (analyticsFeatureKey == 'daily_war') {
    return const SessionAnalyticsLabels(
      featureName: 'daily_war',
      source: 'daily_war',
    );
  }
  if (analyticsFeatureKey == 'daily_war_unranked') {
    return const SessionAnalyticsLabels(
      featureName: 'daily_war_unranked',
      source: 'daily_war',
    );
  }
  if (analyticsFeatureKey == 'daily_current_affairs') {
    return const SessionAnalyticsLabels(
      featureName: 'daily_current_affairs',
      source: 'daily_ca',
    );
  }
  if (analyticsFeatureKey == 'daily_current_affairs_revise') {
    return const SessionAnalyticsLabels(
      featureName: 'daily_current_affairs_revise',
      source: 'daily_ca',
    );
  }
  switch (subject) {
    case 'daily_war':
      return const SessionAnalyticsLabels(
        featureName: 'daily_war',
        source: 'daily_war',
      );
    case 'daily_ca':
      return const SessionAnalyticsLabels(
        featureName: 'daily_current_affairs',
        source: 'daily_ca',
      );
    case 'revision':
    case 'revision_quick':
      return const SessionAnalyticsLabels(
        featureName: 'revision_mode',
        source: 'static_mcq',
      );
    case 'bookmarks':
      return const SessionAnalyticsLabels(
        featureName: 'flashcards',
        source: 'static_mcq',
      );
    default:
      if (subject.toLowerCase().contains('pyq')) {
        return const SessionAnalyticsLabels(
          featureName: 'pyq_mode',
          source: 'pyq',
        );
      }
      return const SessionAnalyticsLabels(
        featureName: 'daily_quiz',
        source: 'static_mcq',
      );
  }
}
