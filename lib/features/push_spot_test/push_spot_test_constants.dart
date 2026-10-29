import '../../core/presentation/topic_label.dart';
import '../../l10n/l10n.dart';

/// Push notification → 1-question spot test → lightweight results.
abstract final class PushSpotTestConstants {
  static const analyticsKey = 'push_spot_test';
  static const followUpAnalyticsKey = 'push_spot_follow_up';

  /// FCM data `kind` for notification tap routing.
  static const fcmKind = 'push_spot_test';

  static const spotQuestionCount = 1;
  static const followUpQuestionCount = 3;

  /// FCM topic all clients subscribe to for spot-test broadcasts.
  static const broadcastFcmTopic = 'upsc_wars_spot_tests';
}

String pushSpotTestResultsRoute(String sessionId) => '/spot-results/$sessionId';

String sessionResultsRouteForKey(
  String sessionId,
  String? analyticsFeatureKey,
) {
  if (analyticsFeatureKey == PushSpotTestConstants.analyticsKey) {
    return pushSpotTestResultsRoute(sessionId);
  }
  if (analyticsFeatureKey == 'daily_war' ||
      analyticsFeatureKey == 'daily_war_unranked') {
    return '/daily-war/results/$sessionId';
  }
  if (analyticsFeatureKey == 'daily_current_affairs') {
    return '/daily-ca/results/$sessionId';
  }
  return '/results/$sessionId';
}

String _slugToLabel(String slug) =>
    slug.trim().replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ');

String displayTopicLabel(String? slug) {
  final s = slug?.trim();
  if (s == null || s.isEmpty) return '';
  return localizedTopicName(
    _slugToLabel(s),
    language: AppL10n.locale.languageCode,
  );
}
