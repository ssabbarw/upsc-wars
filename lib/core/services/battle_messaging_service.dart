import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/analytics/analytics_global_dispatch.dart';
import 'package:upsc_wars/core/debug/cursor_debug_log.dart';
import 'package:upsc_wars/core/debug/upsc_wars_trace.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/router/app_router.dart';
import 'package:upsc_wars/core/services/app_local_notifications_service.dart';
import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';
import 'package:upsc_wars/features/community/open_challenge/open_challenge_fcm.dart';
import 'package:upsc_wars/features/push_spot_test/push_spot_test_fcm.dart';
import 'package:upsc_wars/features/push_spot_test/push_spot_test_launch_params.dart';
import 'package:upsc_wars/features/notifications/long_html_notification_constants.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';
import 'package:upsc_wars/shared/widgets/deferred_push_permission_sheet.dart';

/// FCM setup for battle invites, long HTML announcements, and deep links.
class BattleMessagingService {
  BattleMessagingService._();

  /// Max in-app education sheets per device (then rely on home nudge / settings).
  static const maxDeferredPushEducationSheets = 2;

  /// Set from [main] after [FirebaseMessaging.instance.getInitialMessage] so
  /// the launch intent is not lost before the router exists.
  static RemoteMessage? _pendingOpenedNotification;

  static GoRouter? _router;

  /// iOS throws `permissionRequestInProgress` if `requestPermission()` is called
  /// concurrently. Keep a single in-flight request and share it across callers.
  static Future<AuthorizationStatus?>? _pushPermissionRequestInFlight;

  static void setPendingOpenedNotification(RemoteMessage message) {
    _pendingOpenedNotification = message;
  }

  static Future<void> initialize(GoRouter router) async {
    _router = router;
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS: required for banner/sound while the app is in foreground.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // #region agent log
    unawaited(
      () async {
        final settings = await messaging.getNotificationSettings();
        final apns = await messaging.getAPNSToken();
        final fcm = await messaging.getToken();
        await CursorDebugLog.write(
          hypothesisId: 'A',
          location: 'battle_messaging_service.dart:initialize',
          message: 'Push bootstrap snapshot',
          data: {
            'platform': defaultTargetPlatform.toString(),
            'authStatus': settings.authorizationStatus.toString(),
            'apnsTokenPresent': apns != null && apns.trim().isNotEmpty,
            'fcmTokenPresent': fcm != null && fcm.trim().isNotEmpty,
          },
        );
      }(),
    );
    // #endregion

    if (!kIsWeb) {
      AppLocalNotificationsService.onBattleInviteLocalTap = (sessionId) {
        logGlobalAnalytics(
          const AppNotificationOpenEvent(channel: 'local', kind: 'battle_join'),
        );
        final r = _router;
        if (r == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          r.go('/battle/join/$sessionId');
        });
      };
      AppLocalNotificationsService.onNoTestReminderTap = () {
        logGlobalAnalytics(
          const AppNotificationOpenEvent(
            channel: 'local',
            kind: 'no_test_reminder',
          ),
        );
        final r = _router;
        if (r == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          r.go('/');
        });
      };
      AppLocalNotificationsService.onDailyPracticeReminderTap = () {
        logGlobalAnalytics(
          const AppNotificationOpenEvent(
            channel: 'local',
            kind: 'daily_practice_reminder',
          ),
        );
        final r = _router;
        if (r == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          r.go('/');
        });
      };
      await AppLocalNotificationsService.ensureInitialized();
    }

    FcmTokenSyncService.ensureTokenRefreshSubscription();

    // Foreground: system tray often does not show; surface payload in-app.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleDataMessage);

    final initial =
        _pendingOpenedNotification ?? await messaging.getInitialMessage();
    _pendingOpenedNotification = null;
    if (initial != null) {
      _scheduleNavigateFromOpenedNotification(router, initial, channel: 'fcm');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title?.trim();
    final bodyRaw = n?.body?.trim();
    final resolvedTitle = (title != null && title.isNotEmpty)
        ? title
        : 'Message';
    final resolvedBody = (bodyRaw != null && bodyRaw.isNotEmpty)
        ? bodyRaw
        : (message.data.isEmpty ? 'New notification' : message.data.toString());

    final rawSessionId = message.data['sessionId'];
    final sessionId = rawSessionId == null
        ? null
        : rawSessionId.toString().trim().isEmpty
        ? null
        : rawSessionId.toString().trim();
    final kind = message.data['kind']?.toString().trim().toLowerCase();
    final isSelfTest = kind == 'self_test';
    final isBattleJoinInvite =
        !kIsWeb &&
        !isSelfTest &&
        !messageOpensLongHtmlScreen(message) &&
        sessionId != null &&
        sessionId.isNotEmpty;
    final isChatMessage = kind == 'chat_message';

    if (isBattleJoinInvite) {
      unawaited(
        AppLocalNotificationsService.showForegroundBattleInvite(
          title: resolvedTitle == 'Message' ? 'Battle invite' : resolvedTitle,
          body: resolvedBody == 'New notification'
              ? 'Tap to join this battle'
              : resolvedBody,
          sessionId: sessionId,
        ),
      );
      return;
    }
    if (isChatMessage) {
      return;
    }

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    AppToast.showText(
      ctx,
      '$resolvedTitle\n$resolvedBody',
      duration: const Duration(seconds: 6),
    );
  }

  static void _handleDataMessage(RemoteMessage message) {
    final router = _router;
    if (router == null) return;
    _scheduleNavigateFromOpenedNotification(router, message, channel: 'fcm');
  }

  static void _logNotificationOpen(RemoteMessage message, String channel) {
    var kind = 'unknown';
    if (messageOpensLongHtmlScreen(message)) {
      kind = 'long_html';
    } else if (message.data['kind']?.toString().trim().toLowerCase() ==
        OpenChallengeFcm.kind) {
      kind = 'open_challenge';
    } else if (message.data['kind']?.toString().trim().toLowerCase() ==
        PushSpotTestFcm.kind) {
      kind = PushSpotTestFcm.kind;
    } else {
      final sid = message.data['sessionId']?.toString().trim() ?? '';
      if (sid.isNotEmpty) {
        kind = 'battle_join';
      }
    }
    logGlobalAnalytics(
      AppNotificationOpenEvent(channel: channel, kind: kind),
    );
  }

  /// Opens the long-HTML announcement screen when FCM **data** has
  /// [LongHtmlNotificationConstants.fcmDataKeyType] ==
  /// [LongHtmlNotificationConstants.fcmDataValueLongHtmlMessage] (case-insensitive).
  static bool messageOpensLongHtmlScreen(RemoteMessage message) {
    final raw = message.data[LongHtmlNotificationConstants.fcmDataKeyType];
    if (raw == null) return false;
    final s = raw.toString().trim().toLowerCase();
    return s == LongHtmlNotificationConstants.fcmDataValueLongHtmlMessage;
  }

  /// Routes after notification open (background / terminated).
  static void _scheduleNavigateFromOpenedNotification(
    GoRouter router,
    RemoteMessage message, {
    required String channel,
  }) {
    void go() {
      if (kDebugMode) {
        debugPrint(
          'BattleMessagingService: notification opened, data=${message.data}',
        );
      }
      _logNotificationOpen(message, channel);
      if (messageOpensLongHtmlScreen(message)) {
        router.push('/notification/long-html');
        return;
      }
      final ocKind = message.data['kind']?.toString().trim().toLowerCase();
      if (ocKind == OpenChallengeFcm.kind) {
        final id = message.data[OpenChallengeFcm.challengeId]
            ?.toString()
            .trim();
        if (id != null && id.isNotEmpty) {
          router.go('/community/open-challenges/$id');
        }
        return;
      }
      if (ocKind == PushSpotTestFcm.kind) {
        final params = PushSpotTestLaunchParams(
          subject:
              message.data[PushSpotTestFcm.dataKeySubject]?.toString() ?? '',
          topic: message.data[PushSpotTestFcm.dataKeyTopic]?.toString() ?? '',
          subTopic: () {
            final subRaw =
                message.data[PushSpotTestFcm.dataKeySubtopic] ??
                message.data[PushSpotTestFcm.dataKeySubTopicAlt];
            final s = subRaw?.toString().trim();
            return s != null && s.isNotEmpty ? s : null;
          }(),
          questionUuid: PushSpotTestFcm.questionUuidFromData(message.data),
        );
        if (params.isValid) {
          final uri = Uri(
            path: '/spot-test/launch',
            queryParameters: params.toQueryParameters(),
          );
          router.go(uri.toString());
        }
        return;
      }
      final sessionId = message.data['sessionId'] as String?;
      if (sessionId != null && sessionId.isNotEmpty) {
        router.go('/battle/join/$sessionId');
      }
    }

    // Defer one frame so the shell route is committed before [push] (cold
    // start from notification tap).
    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }

  /// Current OS notification authorization (does not prompt).
  static Future<AuthorizationStatus> notificationAuthorizationStatus() async {
    if (kIsWeb) return AuthorizationStatus.authorized;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) {
        final enabled = await AppLocalNotificationsService.androidNotificationsEnabled();
        if (enabled == true) return AuthorizationStatus.authorized;
        if (enabled == false) return AuthorizationStatus.denied;
      }
    }
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus;
  }

  static bool notificationAuthorizationAllowsPush(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized ||
      s == AuthorizationStatus.provisional;

  static final Set<VoidCallback> _notificationPermissionChangeListeners = {};

  static void addNotificationPermissionChangeListener(VoidCallback listener) {
    _notificationPermissionChangeListeners.add(listener);
  }

  static void removeNotificationPermissionChangeListener(VoidCallback listener) {
    _notificationPermissionChangeListeners.remove(listener);
  }

  static void _notifyNotificationPermissionMayHaveChanged() {
    for (final listener
        in List<VoidCallback>.from(_notificationPermissionChangeListeners)) {
      listener();
    }
  }

  /// Whether the user can receive notifications (or no runtime prompt is needed).
  static Future<bool> notificationsAreEnabled() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt < 33) return true;
      return await AppLocalNotificationsService.androidNotificationsEnabled() ==
          true;
    }
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return notificationAuthorizationAllowsPush(settings.authorizationStatus);
  }

  /// Community/home banner: only when permission was explicitly denied.
  static Future<bool> shouldShowPushDeniedBanner() async {
    if (kIsWeb) return false;
    if (await notificationsAreEnabled()) return false;
    final status = await notificationAuthorizationStatus();
    return status == AuthorizationStatus.denied;
  }

  /// Stable label for [AnalyticsEvent] payloads (not i18n).
  static String notificationAuthorizationStatusLabel(AuthorizationStatus s) {
    if (kIsWeb) return 'web_authorized';
    return switch (s) {
      AuthorizationStatus.authorized => 'authorized',
      AuthorizationStatus.denied => 'denied',
      AuthorizationStatus.notDetermined => 'not_determined',
      AuthorizationStatus.provisional => 'provisional',
    };
  }

  static Future<bool> shouldShowDeferredPushEducationSheet() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PrefKeys.deferredPushPermissionSheetCompletedV1) ??
        false) {
      return false;
    }
    final shown = prefs.getInt(PrefKeys.deferredPushModalShownCountV2) ?? 0;
    return shown < maxDeferredPushEducationSheets;
  }

  /// Prompts when notifications are not yet allowed.
  ///
  /// Shows the in-app education sheet first (at most
  /// [maxDeferredPushEducationSheets] times per device); the OS dialog runs only
  /// if the user taps "Turn on alerts".
  ///
  /// iOS: only when [AuthorizationStatus.notDetermined].
  /// Android 13+: when POST_NOTIFICATIONS is not granted (treats pre-prompt as
  /// not-yet-asked, not denied — [notificationAuthorizationStatus] cannot distinguish).
  static Future<void> requestPushAuthorizationIfNotDetermined({
    String source = 'unknown',
  }) async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) {
        final enabled =
            await AppLocalNotificationsService.androidNotificationsEnabled();
        if (enabled == true) return;
      }
    } else {
      final status = await notificationAuthorizationStatus();
      if (status != AuthorizationStatus.notDetermined) return;
    }

    if (!await shouldShowDeferredPushEducationSheet()) {
      upscWarsTrace(
        'push_education_sheet skipped source=$source (cap or completed)',
      );
      return;
    }

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final accepted = await showDeferredPushPermissionSheet(
      ctx,
      source: source,
    );
    if (accepted != true) return;

    await requestPushAuthorizationAndSync(source: source);
  }

  /// System notification permission + token sync (call after user-facing prompt).
  static Future<AuthorizationStatus?> requestPushAuthorizationAndSync({
    String source = 'unknown',
  }) async {
    if (kIsWeb) return null;
    final inFlight = _pushPermissionRequestInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        // Android 13+: explicitly request POST_NOTIFICATIONS runtime permission.
        if (defaultTargetPlatform == TargetPlatform.android) {
          final granted = await AppLocalNotificationsService
              .requestAndroidNotificationsPermissionIfNeeded();
          if (granted == false) {
            _logPushPermissionPromptResult(AuthorizationStatus.denied, source);
            return AuthorizationStatus.denied;
          }
        }
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          // If the user just granted permission, ensure foreground delivery is visible.
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
        // #region agent log
        unawaited(
          CursorDebugLog.write(
            hypothesisId: 'A',
            location:
                'battle_messaging_service.dart:requestPushAuthorizationAndSync',
            message: 'requestPermission result',
            data: {
              'authStatus': settings.authorizationStatus.toString(),
            },
          ),
        );
        // #endregion
        _logPushPermissionPromptResult(settings.authorizationStatus, source);
        await FcmTokenSyncService.syncForCurrentUser();
        _notifyNotificationPermissionMayHaveChanged();
        return settings.authorizationStatus;
      } finally {
        _pushPermissionRequestInFlight = null;
      }
    }();

    _pushPermissionRequestInFlight = future;
    return future;
  }

  static void _logPushPermissionPromptResult(
    AuthorizationStatus status,
    String source,
  ) {
    logGlobalAnalytics(
      PushPermissionPromptResultEvent(
        status: notificationAuthorizationStatusLabel(status),
        allowsPush: notificationAuthorizationAllowsPush(status),
        source: source,
      ),
    );
  }

  /// Returns the device token for storing on `users/{email}` (server targets invites).
  static Future<String?> refreshFcmToken() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      // #region agent log
      unawaited(
        CursorDebugLog.write(
          hypothesisId: 'B',
          location: 'battle_messaging_service.dart:refreshFcmToken',
          message: 'FirebaseMessaging.getToken result',
          data: {
            'fcmTokenPresent': t != null && t.trim().isNotEmpty,
          },
        ),
      );
      // #endregion
      return t;
    } catch (e, st) {
      debugPrint('BattleMessagingService.refreshFcmToken: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }
}
