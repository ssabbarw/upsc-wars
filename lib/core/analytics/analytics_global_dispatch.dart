import 'analytics_events.dart';

/// Binds a global way to [AnalyticsService.track] from static services (FCM,
/// [Share], share links). **Call [bindGlobalAnalytics] once** from
/// [UpscWarsApp] and pass `null` in the effect cleanup.
void Function(AnalyticsEvent)? _send;

void bindGlobalAnalytics([void Function(AnalyticsEvent)? send]) {
  _send = send;
}

/// Fire-and-forget dispatch; no-op if [bindGlobalAnalytics] was not set.
void logGlobalAnalytics(AnalyticsEvent e) {
  _send?.call(e);
}
