import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/admin_dashboard/admin_dashboard_collection_config.dart';
import '../../../core/admin_dashboard/admin_dashboard_period.dart';
import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/providers/kill_switch_provider.dart';

final adminDashboardWriterProvider = Provider<AdminDashboardWriterService>(
  (ref) => AdminDashboardWriterService(),
);

final adminDashboardReaderProvider = Provider<AdminDashboardReaderService>(
  (ref) => AdminDashboardReaderService(),
);

/// Super-user-only admin analytics dashboard.
bool canAccessAdminDashboard({required bool isSuperUser}) => isSuperUser;

/// Loads one period summary (Firestore reads).
final adminDashboardPeriodSummaryProvider =
    FutureProvider.family<AdminDashboardPeriodSummary, AdminDashboardPeriod>(
  (ref, period) async {
    return ref.read(adminDashboardReaderProvider).loadPeriodSummary(period);
  },
);

final adminDashboardNotificationsProvider =
    FutureProvider<List<AdminDashboardNotificationStats>>((ref) async {
  return ref.read(adminDashboardReaderProvider).loadNotifications();
});

/// Remote Config gate for client-side metric collection (after RC fetch).
final adminDashboardCollectionEnabledProvider = FutureProvider<bool>((ref) async {
  await ref.watch(killSwitchProvider.future);
  return isAdminDashboardCollectionEnabled();
});
