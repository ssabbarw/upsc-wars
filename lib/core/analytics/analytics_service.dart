import 'dart:developer' as developer;

import 'analytics_events.dart';
import 'analytics_sink.dart';

/// Central analytics API. UI and repositories call [track] only through this
/// service (via Riverpod), never Firebase or Drift directly.
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
