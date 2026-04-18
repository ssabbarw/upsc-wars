import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/analytics_provider.dart';
import 'analytics_events.dart';

/// App-wide analytics entry point for UI and hooks (`WidgetRef`).
/// For `@Riverpod` functions that receive `Ref`, use
/// `ref.read(analyticsServiceProvider).track(event)` the same way
/// [AnalyticsService] is used from repositories.
abstract final class Analytics {
  const Analytics._();

  static Future<void> track(WidgetRef ref, AnalyticsEvent event) {
    return ref.read(analyticsServiceProvider).track(event);
  }
}
