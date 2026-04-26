import 'dart:ui' show Color;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/prelims_countdown.dart';
import '../constants/prelims_debug_flags.dart';
import '../providers/prefs_provider.dart';

/// Single [FlutterLocalNotificationsPlugin] for prelims + foreground FCM targets.
class AppLocalNotificationsService {
  AppLocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Future<void>? _initInFlight;

  /// Set from [BattleMessagingService] before [ensureInitialized] so taps route correctly.
  static void Function(String sessionId)? onBattleInviteLocalTap;

  static const _battleChannelId = 'battle_invites_foreground';
  static const _battleChannelName = 'Battle invites';
  static const _battleChannelDescription =
      'Battle invites while you are in the app (tap to join)';

  // IMPORTANT: Android channels are sticky. We versioned this channel so existing
  // installs that previously had a silent/low-importance default channel will
  // get a brand-new, loud channel without needing a user setting change.
  static const _generalChannelIdV1 = 'general';
  static const _generalChannelIdV2 = 'general_v2';
  static const _generalChannelName = 'General';
  static const _generalChannelDescription = 'General app notifications';

  /// One slot so a new foreground invite replaces the previous banner.
  static const foregroundBattleInviteNotificationId = 9001;

  static const prelimsPersistentNotificationId = 7001;

  static const _prelimsChannelId = 'prelims_countdown_channel';
  static const _prelimsChannelName = 'Prelims Countdown';
  static const _prelimsChannelDescription =
      'Persistent UPSC prelims countdown reminder';

  static Future<int?> _androidSdkInt() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  /// Android 13+ requires a runtime permission for posting notifications.
  static Future<bool?> requestAndroidNotificationsPermissionIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final sdkInt = await _androidSdkInt();
    if (sdkInt == null || sdkInt < 33) return true;
    await ensureInitialized();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return androidImpl?.requestNotificationsPermission();
  }

  static Future<bool?> androidNotificationsEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    await ensureInitialized();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return androidImpl?.areNotificationsEnabled();
  }

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (kIsWeb) return;
    final inFlight = _initInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        const darwinInit = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@drawable/ic_notification'),
            iOS: darwinInit,
            macOS: darwinInit,
          ),
          onDidReceiveNotificationResponse: _onNotificationResponse,
        );

        // Create a loud default channel for FCM background notifications.
        // Android 8+ channels are sticky; ensure this exists early.
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        // Keep v1 around (older builds may have referenced it), but default new
        // FCM deliveries to v2 via AndroidManifest meta-data.
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _generalChannelIdV1,
            _generalChannelName,
            description: _generalChannelDescription,
            importance: Importance.high,
          ),
        );
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _generalChannelIdV2,
            _generalChannelName,
            description: _generalChannelDescription,
            importance: Importance.high,
          ),
        );

        _initialized = true;
      } finally {
        _initInFlight = null;
      }
    }();

    _initInFlight = future;
    return future;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('battle_join:')) return;
    final sessionId = payload.substring('battle_join:'.length).trim();
    if (sessionId.isEmpty) return;
    onBattleInviteLocalTap?.call(sessionId);
  }

  /// Heads-up style local notification so the user can tap through to join while in-app.
  static Future<void> showForegroundBattleInvite({
    required String title,
    required String body,
    required String sessionId,
  }) async {
    if (kIsWeb) return;
    await ensureInitialized();

    const androidChannel = AndroidNotificationChannel(
      _battleChannelId,
      _battleChannelName,
      description: _battleChannelDescription,
      importance: Importance.high,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);

    await _plugin.show(
      id: foregroundBattleInviteNotificationId,
      title: title.isNotEmpty ? title : 'Battle invite',
      body: body.isNotEmpty ? body : 'Tap to join',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _battleChannelId,
          _battleChannelName,
          channelDescription: _battleChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF085041),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          category: AndroidNotificationCategory.social,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'battle_join:$sessionId',
    );
  }

  /// Android prelims persistent notification (same behaviour as before consolidation).
  static Future<void> syncPrelimsPersistentNotification() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(PrefKeys.prelimsPersistentNotification) ?? false;

    await ensureInitialized();

    if (!enabled) {
      await _plugin.cancel(id: prelimsPersistentNotificationId);
      return;
    }

    final now = DateTime.now();
    final title = PrelimsCountdown.persistentNotificationTitle();
    var body = PrelimsCountdown.persistentNotificationBody(now: now);
    if (PrelimsDebugFlags.surfacesEveryMinute) {
      body = '$body\n@${DateFormat('HH:mm').format(now)}';
    }

    const androidDetails = AndroidNotificationDetails(
      _prelimsChannelId,
      _prelimsChannelName,
      channelDescription: _prelimsChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      icon: '@drawable/ic_notification',
      color: Color(0xFF085041),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    await _plugin.show(
      id: prelimsPersistentNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
