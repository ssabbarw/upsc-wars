import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/debug/upsc_wars_trace.dart';
import 'package:upsc_wars/core/services/fcm_token_sync_service.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';
import 'package:upsc_wars/shared/widgets/deferred_push_permission_sheet.dart';

enum EnsurePushResult {
  alreadyEnabled,
  promptedSystem,
  openedSettings,
  rateLimited,
  userDeclinedEducation,
  skippedWeb,
  error,
}

class PushNotificationsEnsureService {
  PushNotificationsEnsureService._();

  static const Duration _systemPromptCooldown = Duration(hours: 24);

  static Future<EnsurePushResult> ensureEnabled(
    BuildContext context,
    WidgetRef ref, {
    required String source,
    bool allowEducationSheet = true,
    bool showRateLimitToast = true,
  }) async {
    if (kIsWeb) return EnsurePushResult.skippedWeb;
    try {
      final status = await BattleMessagingService.notificationAuthorizationStatus();
      upscWarsTrace(
        'PushNotificationsEnsureService.ensureEnabled '
        'source=$source status=$status allowEducationSheet=$allowEducationSheet',
      );

      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        // Already enabled: just ensure token is present/up to date.
        await FcmTokenSyncService.syncForCurrentUser();
        return EnsurePushResult.alreadyEnabled;
      }

      if (status == AuthorizationStatus.denied) {
        upscWarsTrace(
          'PushNotificationsEnsureService.ensureEnabled '
          'source=$source action=open_settings',
        );
        if (context.mounted) {
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
        }
        return EnsurePushResult.openedSettings;
      }

      // notDetermined: only show education if we can show the OS prompt today.
      final prefs = await ref.read(prefsServiceProvider.future);
      final now = DateTime.now();
      final lastMs = prefs.pushSystemPromptLastShownAtMs;
      final last = lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs);
      final canPromptToday =
          last == null || now.difference(last) >= _systemPromptCooldown;

      if (!canPromptToday) {
        upscWarsTrace(
          'PushNotificationsEnsureService.ensureEnabled '
          'source=$source action=rate_limited lastMs=$lastMs',
        );
        if (showRateLimitToast && context.mounted) {
          AppToast.showText(
            context,
            'We already asked today. Try again tomorrow, or enable notifications in Settings.',
          );
        }
        return EnsurePushResult.rateLimited;
      }

      bool wantPrompt = true;
      if (allowEducationSheet) {
        if (!context.mounted) return EnsurePushResult.error;
        upscWarsTrace(
          'PushNotificationsEnsureService.ensureEnabled '
          'source=$source action=show_education_sheet',
        );
        final v = await showDeferredPushPermissionSheet(context);
        wantPrompt = v == true;
        upscWarsTrace(
          'PushNotificationsEnsureService.ensureEnabled '
          'source=$source education_result=$v',
        );
        if (!wantPrompt) return EnsurePushResult.userDeclinedEducation;
      }

      prefs.pushSystemPromptLastShownAtMs = now.millisecondsSinceEpoch;
      upscWarsTrace(
        'PushNotificationsEnsureService.ensureEnabled '
        'source=$source action=request_system_permission setLastMs=${prefs.pushSystemPromptLastShownAtMs}',
      );
      await BattleMessagingService.requestPushAuthorizationAndSync();
      return EnsurePushResult.promptedSystem;
    } catch (e, st) {
      upscWarsTrace(
        'PushNotificationsEnsureService.ensureEnabled error source=$source',
        error: e,
        stackTrace: st,
      );
      // Don't crash UX; just report "error" upstream.
      return EnsurePushResult.error;
    }
  }
}

