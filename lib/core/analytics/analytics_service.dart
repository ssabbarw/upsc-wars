import 'dart:developer' as developer;

import 'analytics_audience.dart';
import 'analytics_events.dart';
import 'analytics_sink.dart';

/// In-process hub: one [track] call fan-outs to all registered [AnalyticsSink]s
/// (e.g. [FirebaseAnalyticsSink] for GA4, [LocalAnalyticsSink] for Drift).
///
/// **Product meaning of each [AnalyticsEvent]** is documented in English on the
/// event class in [analytics_events.dart], not here.
///
/// Debug builds, admins, and bots never reach the sinks — see [AnalyticsAudience].
class AnalyticsService {
  AnalyticsService(
    this._sinks, {
    bool Function()? skipCapture,
  }) : _skipCapture = skipCapture ?? AnalyticsAudience.isCurrentUserExcluded;

  final List<AnalyticsSink> _sinks;
  final bool Function() _skipCapture;

  Future<void> track(AnalyticsEvent event) async {
    if (_skipCapture()) return;
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
