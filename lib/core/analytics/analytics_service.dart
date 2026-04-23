import 'dart:developer' as developer;

import 'analytics_events.dart';
import 'analytics_sink.dart';

/// In-process hub: one [track] call fan-outs to all registered [AnalyticsSink]s
/// (e.g. [FirebaseAnalyticsSink] for GA4, [LocalAnalyticsSink] for Drift).
///
/// **Product meaning of each [AnalyticsEvent]** is documented in English on the
/// event class in [analytics_events.dart], not here.
class AnalyticsService {
  AnalyticsService(this._sinks);

  final List<AnalyticsSink> _sinks;

  Future<void> track(AnalyticsEvent event) async {
    for (final sink in _sinks) {
      try {
        await sink.send(event);
      } catch (e, st) {
        developer.log(
          'AnalyticsSink failed: $e',
          name: 'AnalyticsService',
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}
