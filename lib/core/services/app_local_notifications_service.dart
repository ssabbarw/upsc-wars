import 'dart:ui' show Color;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/prelims_countdown.dart';
import '../constants/prelims_debug_flags.dart';
import '../debug/upsc_wars_trace.dart';
import '../providers/prefs_provider.dart';
import '../../features/chat/chat_fcm.dart';

/// One pre-scheduled Daily Drill reminder in the rolling window.
typedef ScheduledDrillReminder = ({
  int id,
  DateTime fireAtLocal,
  String title,
  String body,
});

/// Single [FlutterLocalNotificationsPlugin] for prelims + foreground FCM targets.
class AppLocalNotificationsService {
  AppLocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Future<void>? _initInFlight;

  /// Set from [BattleMessagingService] before [ensureInitialized] so taps route correctly.
  static void Function(String sessionId)? onBattleInviteLocalTap;

  /// Opens home when the no-test reminder notification is tapped.
  static void Function()? onNoTestReminderTap;

  /// Starts the static drill when the daily practice reminder is tapped.
  static void Function()? onDailyPracticeReminderTap;

  /// Opens today's paper quiz when the morning CA reminder is tapped.
  static void Function()? onDailyCaPaperReminderTap;

  /// Opens the Fomo Pulse detail screen when a foreground pulse tap fires.
  static void Function(String pulseId)? onFomoPulseLocalTap;

  /// Opens a chat thread when a foreground chat notification is tapped.
  static void Function({
    required String chatId,
    required String senderEmail,
    required String senderName,
  })?
  onChatMessageLocalTap;

  /// Holds a pulse ID that arrived before [onFomoPulseLocalTap] was wired.
  static String? _pendingFomoPulseId;

  static ({String chatId, String senderEmail, String senderName})?
  _pendingChatTap;

  static const _noTestReminderChannelId = 'no_test_reminder_v1';
  static const _noTestReminderChannelName = 'Study reminders';
  static const _noTestReminderChannelDescription =
      'Reminders to take your first practice test';

  static const _noTestReminderTitle = 'Find where UPSC Wars gives you an edge';
  static const _noTestReminderBody =
      'Take 7 quick MCQs. Get coached to eliminate better, spot weak areas, and see where you\u2019re strong.';

  static const _battleChannelId = 'battle_invites_foreground';
  static const _battleChannelName = 'Battle invites';
  static const _battleChannelDescription =
      'Battle invites while you are in the app (tap to join)';

  static const _fomoPulseChannelId = 'fomo_pulse_v1';
  static const _fomoPulseChannelName = 'CA Shots';
  static const _fomoPulseChannelDescription =
      'Breaking news quizzes from UPSC Wars';

  static const _chatChannelId = 'chat_messages_v1';
  static const _chatChannelName = 'Chat';
  static const _chatChannelDescription =
      'Direct messages while you are in the app (tap to open)';

  static const foregroundFomoPulseNotificationId = 9002;
  static const foregroundChatMessageNotificationId = 9003;

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

  static const noTestReminderNotificationId = 8001;
  static const noTestReminderPayload = 'no_test_reminder';

  /// Legacy single-slot id, cancelled in favour of the rolling window below.
  static const dailyPracticeReminderNotificationId = 8002;
  static const dailyPracticeReminderPayload = 'daily_practice_reminder';

  /// One id per day of the pending drill-reminder window.
  ///
  /// Only an app open re-arms these, so a single pending reminder goes quiet
  /// after one skipped day — precisely when a lapsing user still needs it.
  static const dailyPracticeReminderWindowIds = <int>[
    8010,
    8011,
    8012,
    8013,
    8014,
    8015,
    8016,
  ];

  static const dailyCaPaperReminderNotificationId = 8003;
  static const dailyCaPaperReminderPayload = 'daily_ca_paper_reminder';

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
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return androidImpl?.requestNotificationsPermission();
  }

  static Future<bool?> androidNotificationsEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    await ensureInitialized();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
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
            importance: Importance.max,
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

  /// Re-dispatch a cold-start local notification tap after tap handlers are wired.
  ///
  /// [main] may call [ensureInitialized] for prelims before
  /// [BattleMessagingService.initialize] registers payloads — without this, daily
  /// drill / CA reminder taps can be dropped on process launch.
  static Future<void> dispatchLaunchNotificationIfNeeded() async {
    if (kIsWeb || !_initialized) return;
    final details = await _plugin.getNotificationAppLaunchDetails();
    upscWarsTrace(
      'LocalNotification launchDetails didLaunch='
      '${details?.didNotificationLaunchApp} '
      'payload=${details?.notificationResponse?.payload}',
    );
    if (details?.didNotificationLaunchApp != true) return;
    final response = details!.notificationResponse;
    if (response == null) return;
    _onNotificationResponse(response);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    upscWarsTrace('LocalNotification tap payload=$payload');
    if (payload == null) return;
    if (payload.startsWith('battle_join:')) {
      final sessionId = payload.substring('battle_join:'.length).trim();
      if (sessionId.isEmpty) return;
      onBattleInviteLocalTap?.call(sessionId);
      return;
    }
    if (payload == noTestReminderPayload) {
      onNoTestReminderTap?.call();
      return;
    }
    if (payload == dailyPracticeReminderPayload) {
      onDailyPracticeReminderTap?.call();
      return;
    }
    if (payload == dailyCaPaperReminderPayload) {
      onDailyCaPaperReminderTap?.call();
      return;
    }
    if (payload.startsWith('fomo_pulse:')) {
      final pulseId = payload.substring('fomo_pulse:'.length).trim();
      if (pulseId.isEmpty) return;
      final handler = onFomoPulseLocalTap;
      upscWarsTrace(
        'LocalNotification fomo_pulse id=$pulseId handlerReady=${handler != null}',
      );
      if (handler != null) {
        handler(pulseId);
      } else {
        _pendingFomoPulseId = pulseId;
      }
      return;
    }
    final chatTap = ChatFcm.parseLocalPayload(payload);
    if (chatTap != null) {
      final handler = onChatMessageLocalTap;
      upscWarsTrace(
        'LocalNotification chat_message chatIdLen=${chatTap.chatId.length} '
        'handlerReady=${handler != null}',
      );
      if (handler != null) {
        handler(
          chatId: chatTap.chatId,
          senderEmail: chatTap.senderEmail,
          senderName: chatTap.senderName,
        );
      } else {
        _pendingChatTap = chatTap;
      }
    }
  }

  /// Called by [BattleMessagingService] after wiring [onFomoPulseLocalTap].
  /// Flushes any tap that arrived before the handler was ready.
  static void consumePendingFomoPulseTap() {
    final id = _pendingFomoPulseId;
    if (id == null) return;
    _pendingFomoPulseId = null;
    onFomoPulseLocalTap?.call(id);
  }

  /// Called by [BattleMessagingService] after wiring [onChatMessageLocalTap].
  static void consumePendingChatMessageTap() {
    final tap = _pendingChatTap;
    if (tap == null) return;
    _pendingChatTap = null;
    onChatMessageLocalTap?.call(
      chatId: tap.chatId,
      senderEmail: tap.senderEmail,
      senderName: tap.senderName,
    );
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
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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

  /// Shows a heads-up system notification for a Fomo Pulse received in foreground.
  /// Tapping routes to the pulse detail screen via [onFomoPulseLocalTap].
  static Future<void> showForegroundFomoPulse({
    required String title,
    required String body,
    required String pulseId,
  }) async {
    if (kIsWeb) return;
    await ensureInitialized();

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _fomoPulseChannelId,
        _fomoPulseChannelName,
        description: _fomoPulseChannelDescription,
        importance: Importance.max,
      ),
    );

    await _plugin.show(
      id: foregroundFomoPulseNotificationId,
      title: title.isNotEmpty ? title : 'CA Shot',
      body: body.isNotEmpty ? body : 'Tap to read & attempt',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _fomoPulseChannelId,
          _fomoPulseChannelName,
          channelDescription: _fomoPulseChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF085041),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          category: AndroidNotificationCategory.recommendation,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'fomo_pulse:$pulseId',
    );
    upscWarsTrace('LocalNotification posted fomo_pulse:$pulseId');
  }

  /// Heads-up system notification for a chat message received in the foreground.
  /// Tapping routes to the thread via [onChatMessageLocalTap].
  static Future<void> showForegroundChatMessage({
    required String title,
    required String body,
    required String chatId,
    required String senderEmail,
    String? senderName,
  }) async {
    if (kIsWeb) return;
    await ensureInitialized();

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chatChannelId,
        _chatChannelName,
        description: _chatChannelDescription,
        importance: Importance.high,
      ),
    );

    await _plugin.show(
      id: foregroundChatMessageNotificationId,
      title: title.isNotEmpty ? title : 'New message',
      body: body.isNotEmpty ? body : 'Tap to open chat',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _chatChannelId,
          _chatChannelName,
          channelDescription: _chatChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF085041),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          category: AndroidNotificationCategory.message,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: ChatFcm.localPayload(
        chatId: chatId,
        senderEmail: senderEmail,
        senderName: senderName ?? title,
      ),
    );
    upscWarsTrace('LocalNotification posted chat_message');
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

  static NotificationDetails _noTestReminderDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _noTestReminderChannelId,
        _noTestReminderChannelName,
        channelDescription: _noTestReminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: const Color(0xFF085041),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> _ensureNoTestReminderChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _noTestReminderChannelId,
        _noTestReminderChannelName,
        description: _noTestReminderChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Schedules the day-after-install reminder. Returns false if scheduling failed.
  static Future<bool> scheduleNoTestReminder({
    required DateTime fireAtLocal,
  }) async {
    if (kIsWeb) return false;
    await ensureInitialized();
    await _ensureNoTestReminderChannel();

    final scheduledDate = tz.TZDateTime.from(fireAtLocal, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: noTestReminderNotificationId,
        title: _noTestReminderTitle,
        body: _noTestReminderBody,
        scheduledDate: scheduledDate,
        notificationDetails: _noTestReminderDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: noTestReminderPayload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Immediate fallback when the scheduled time has already passed.
  static Future<void> showNoTestReminder() async {
    if (kIsWeb) return;
    await ensureInitialized();
    await _ensureNoTestReminderChannel();
    await _plugin.show(
      id: noTestReminderNotificationId,
      title: _noTestReminderTitle,
      body: _noTestReminderBody,
      notificationDetails: _noTestReminderDetails(),
      payload: noTestReminderPayload,
    );
  }

  static Future<void> cancelNoTestReminder() async {
    if (kIsWeb) return;
    await ensureInitialized();
    await _plugin.cancel(id: noTestReminderNotificationId);
  }

  static NotificationDetails _dailyPracticeReminderDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _noTestReminderChannelId,
        _noTestReminderChannelName,
        channelDescription: _noTestReminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: const Color(0xFF085041),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Replaces the pending drill window with [reminders]; unused slots are cleared.
  static Future<void> scheduleDailyPracticeReminders(
    List<ScheduledDrillReminder> reminders,
  ) async {
    if (kIsWeb) return;
    await ensureInitialized();
    await _ensureNoTestReminderChannel();
    await _plugin.cancel(id: dailyPracticeReminderNotificationId);

    final scheduledIds = {for (final r in reminders) r.id};
    for (final id in dailyPracticeReminderWindowIds) {
      if (scheduledIds.contains(id)) continue;
      await _plugin.cancel(id: id);
    }

    for (final reminder in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.fireAtLocal, tz.local),
          notificationDetails: _dailyPracticeReminderDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: dailyPracticeReminderPayload,
        );
      } catch (_) {
        // Best-effort scheduling.
      }
    }
  }

  static Future<void> cancelDailyPracticeReminder() async {
    if (kIsWeb) return;
    await ensureInitialized();
    await _plugin.cancel(id: dailyPracticeReminderNotificationId);
    for (final id in dailyPracticeReminderWindowIds) {
      await _plugin.cancel(id: id);
    }
  }

  /// The one morning push: the paper quiz, plus tonight's War topics when known.
  static Future<void> scheduleDailyCaPaperReminder({
    required DateTime fireAtLocal,
    required int questionCount,
    String? warTopicsLine,
  }) async {
    if (kIsWeb) return;
    await ensureInitialized();
    await _ensureNoTestReminderChannel();

    final scheduledDate = tz.TZDateTime.from(fireAtLocal, tz.local);
    final body = warTopicsLine == null || warTopicsLine.isEmpty
        ? '$questionCount MCQs from the news you just read'
        : '$questionCount MCQs from the news · Tonight: $warTopicsLine';
    try {
      await _plugin.zonedSchedule(
        id: dailyCaPaperReminderNotificationId,
        title: "Today's paper quiz is live",
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _dailyPracticeReminderDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: dailyCaPaperReminderPayload,
      );
    } catch (_) {
      // Best-effort scheduling.
    }
  }

  static Future<void> cancelDailyCaPaperReminder() async {
    if (kIsWeb) return;
    await ensureInitialized();
    await _plugin.cancel(id: dailyCaPaperReminderNotificationId);
  }
}
