import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/analytics_provider.dart';
import 'analytics_events.dart';

/// UI helper: [track] reads [analyticsServiceProvider] and forwards to
/// [AnalyticsService]. For `@Riverpod` [Ref] (no [WidgetRef]), use
/// `ref.read(analyticsServiceProvider).track(event)` instead.
///
/// **What each event means** — see the Dartdoc on each class in
/// [analytics_events.dart]; **GA4 event `name` + params** — see
/// [FirebaseAnalyticsSink] top-level comment.
abstract final class Analytics {
  const Analytics._();

  static Future<void> track(WidgetRef ref, AnalyticsEvent event) {
    return ref.read(analyticsServiceProvider).track(event);
  }
}
