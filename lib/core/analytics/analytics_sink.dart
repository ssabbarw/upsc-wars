import 'analytics_events.dart';

/// Pluggable “backend” for [AnalyticsService] (e.g. GA4 + local Drift). Each
/// [send] maps [AnalyticsEvent] to that sink’s storage; the canonical GA4
/// `logEvent` names and parameters for Firebase are defined in
/// [FirebaseAnalyticsSink] only.
abstract class AnalyticsSink {
  /// Dispatch one [AnalyticsEvent] (e.g. log to Firebase, update Drift).
  Future<void> send(AnalyticsEvent event);
}
