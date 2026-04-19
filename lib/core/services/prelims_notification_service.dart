import 'package:flutter/foundation.dart';

import 'app_local_notifications_service.dart';

class PrelimsNotificationService {
  PrelimsNotificationService._();

  /// Shows, updates, or clears the persistent prelims notification from prefs.
  static Future<void> syncPersistentNotification() async {
    if (kIsWeb) return;
    await AppLocalNotificationsService.syncPrelimsPersistentNotification();
  }
}
