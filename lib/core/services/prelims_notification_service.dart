import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/prelims_countdown.dart';
import '../constants/prelims_debug_flags.dart';
import '../providers/prefs_provider.dart';

class PrelimsNotificationService {
  PrelimsNotificationService._();

  static const _channelId = 'prelims_countdown_channel';
  static const _channelName = 'Prelims Countdown';
  static const _channelDescription =
      'Persistent UPSC prelims countdown reminder';
  static const _notificationId = 7001;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings: initializationSettings);
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Shows, updates, or clears the persistent prelims notification from prefs.
  static Future<void> syncPersistentNotification() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(PrefKeys.prelimsPersistentNotification) ?? true;

    await _ensureInitialized();

    if (!enabled) {
      await _notifications.cancel(id: _notificationId);
      return;
    }

    final now = DateTime.now();
    final title = PrelimsCountdown.persistentNotificationTitle();
    var body = PrelimsCountdown.persistentNotificationBody(now: now);
    if (PrelimsDebugFlags.surfacesEveryMinute) {
      body = '$body\n@${DateFormat('HH:mm').format(now)}';
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    await _notifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
