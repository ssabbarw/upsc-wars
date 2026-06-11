import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../analytics/analytics_service.dart';
import '../analytics/firebase_analytics_sink.dart';
import '../analytics/local_analytics_sink.dart';
import '../admin_dashboard/admin_dashboard_analytics_sink.dart';
import 'user_database_provider.dart';

part 'analytics_provider.g.dart';

/// Global [AnalyticsService] wiring [FirebaseAnalyticsSink] and
/// [LocalAnalyticsSink]; event meanings are on each [AnalyticsEvent] subclass.
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  final db = ref.watch(userDatabaseProvider);
  return AnalyticsService([
    FirebaseAnalyticsSink(),
    LocalAnalyticsSink(db),
    AdminDashboardAnalyticsSink(),
  ]);
}
