import 'prelims_notification_service.dart';
import 'prelims_widget_sync_service.dart';

/// Keeps the Prelims home/lock widgets and the Android persistent notification
/// aligned with [PrelimsCountdown] (same as app open + periodic background run).
class PrelimsSurfacesRefresh {
  PrelimsSurfacesRefresh._();

  static const String periodicTaskUniqueName = 'prelims_surfaces_refresh_periodic';
  static const String periodicTaskName = 'prelimsSurfacesRefresh';

  static Future<void> refreshAllSurfaces() async {
    await PrelimsWidgetSyncService.sync();
    await PrelimsNotificationService.syncPersistentNotification();
  }
}
