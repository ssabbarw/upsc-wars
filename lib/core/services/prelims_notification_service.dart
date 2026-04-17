import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/prelims_countdown.dart';

class PrelimsNotificationService {
  PrelimsNotificationService._();

  static const _channelId = 'prelims_countdown_channel';
  static const _channelName = 'Prelims Countdown';
  static const _channelDescription =
      'Persistent UPSC prelims countdown reminder';
  static const _notificationId = 7001;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> showPersistentCountdown() async {
    if (!Platform.isAndroid) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings: initializationSettings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

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

    final now = DateTime.now();
    await _notifications.show(
      id: _notificationId,
      title: 'Prelims countdown ${PrelimsCountdown.timerLabel(now: now)}',
      body: PrelimsCountdown.quoteForDate(now: now),
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
