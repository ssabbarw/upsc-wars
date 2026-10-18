import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../analytics/analytics_service.dart';
import '../analytics/firebase_analytics_sink.dart';
import '../analytics/local_analytics_sink.dart';
import '../analytics/posthog_analytics_sink.dart';
import '../admin_dashboard/admin_dashboard_analytics_sink.dart';
import 'user_database_provider.dart';

part 'analytics_provider.g.dart';

/// Global [AnalyticsService] wiring Firebase, PostHog, Drift, and admin
/// dashboard sinks; event meanings are on each [AnalyticsEvent] subclass.
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  final db = ref.watch(userDatabaseProvider);
  return AnalyticsService([
    FirebaseAnalyticsSink(),
    PostHogAnalyticsSink(),
    LocalAnalyticsSink(db),
    AdminDashboardAnalyticsSink(),
  ]);
}
