import 'analytics_events.dart';

abstract class AnalyticsSink {
  Future<void> send(AnalyticsEvent event);
}
