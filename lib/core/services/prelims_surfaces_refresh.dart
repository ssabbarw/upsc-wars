import 'prelims_notification_service.dart';

/// Keeps the Android persistent Prelims notification aligned with [PrelimsCountdown]
/// (same as app open + periodic background run).
class PrelimsSurfacesRefresh {
  PrelimsSurfacesRefresh._();

  static const String periodicTaskUniqueName = 'prelims_surfaces_refresh_periodic';
  static const String periodicTaskName = 'prelimsSurfacesRefresh';

  static Future<void> refreshAllSurfaces() async {
    await PrelimsNotificationService.syncPersistentNotification();
  }
}
