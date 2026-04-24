import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/analytics.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/debug/upsc_wars_trace.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/services/push_notifications_ensure_service.dart';
import 'package:upsc_wars/shared/widgets/deferred_push_permission_sheet.dart';

/// Defers the system notification prompt until the user has completed a test
/// or signed in from the Community tab. At most **two** education modals; then
/// a lightweight home hint (see [homeNudgeShouldShow]).
class DeferredPushPermissionCoordinator {
  DeferredPushPermissionCoordinator._();

  static const int _maxEducationModals = 2;

  static bool _communitySignInArmed = false;
  static bool _offerInFlight = false;

  /// Call immediately before starting Google sign-in from the Community tab.
  static void armCommunitySignInPrompt() {
    _communitySignInArmed = true;
    upscWarsTrace('DeferredPushPermissionCoordinator.armCommunitySignInPrompt');
  }

  /// Clears an armed community prompt (e.g. sign-in cancelled or failed).
  static void clearCommunitySignInArmed() {
    _communitySignInArmed = false;
    upscWarsTrace(
      'DeferredPushPermissionCoordinator.clearCommunitySignInArmed',
    );
  }

  static bool _takeCommunitySignInArmed() {
    if (!_communitySignInArmed) return false;
    _communitySignInArmed = false;
    return true;
  }

  /// Auth listener: call when the user transitions from signed-out to signed-in.
  ///
  /// [onSignedInFromCommunityTab] runs after sign-in that began from the Community
  /// tab (before the deferred notification sheet, if any).
  static Future<void> onSignedInAfterCommunityPromptArmed(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onSignedInFromCommunityTab,
  }) async {
    final taken = _takeCommunitySignInArmed();
    upscWarsTrace(
      'DeferredPushPermissionCoordinator.onSignedInAfterCommunityPromptArmed '
      'armedTaken=$taken mounted=${context.mounted}',
    );
    if (!taken) return;
    onSignedInFromCommunityTab?.call();
    await _offerIfNeeded(
      context,
      ref,
      requireCompletedSession: false,
      source: 'community_signin',
    );
  }

  /// After a completed test: offer the notification education sheet from explicit
  /// user actions only (e.g. Go back / Home, Review explanations), not on mount.
  static Future<void> tryOfferFromResultsUserAction(
    BuildContext context,
    WidgetRef ref,
  ) async {
    upscWarsTrace(
      'DeferredPushPermissionCoordinator.tryOfferFromResultsUserAction '
      'mounted=${context.mounted}',
    );
    await _offerIfNeeded(
      context,
      ref,
      requireCompletedSession: true,
      source: 'post_test',
    );
  }

  /// Whether to show the one-line home notification hint (after 2 modals).
  static Future<bool> homeNudgeShouldShow(Ref ref) async {
    if (kIsWeb) return false;
    final prefs = await ref.watch(prefsServiceProvider.future);
    if (prefs.deferredPushPermissionSheetCompletedV1) return false;
    if (prefs.deferredPushModalShownCountV2 < _maxEducationModals) return false;
    if (prefs.deferredPushHomeNudgeDismissedV2) return false;
    final status = await BattleMessagingService.notificationAuthorizationStatus();
    return !BattleMessagingService.notificationAuthorizationAllowsPush(status);
  }

  static Future<void> _offerIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    required bool requireCompletedSession,
    required String source,
  }) async {
    if (kIsWeb) return;
    try {
      upscWarsTrace(
        'DeferredPushPermissionCoordinator._offerIfNeeded start '
        'source=$source requireCompletedSession=$requireCompletedSession '
        'mounted=${context.mounted}',
      );
      final prefs = await ref.read(prefsServiceProvider.future);
      if (prefs.deferredPushPermissionSheetCompletedV1) {
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded skip '
          'source=$source reason=legacy_completed_v1',
        );
        return;
      }
      if (prefs.deferredPushModalShownCountV2 >= _maxEducationModals) {
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded skip '
          'source=$source reason=modal_quota_reached '
          'shown=${prefs.deferredPushModalShownCountV2}',
        );
        return;
      }

      if (requireCompletedSession) {
        final db = ref.read(userDatabaseProvider);
        final n = await db.sessionsDao.countCompletedSessions();
        if (n < 1) {
          upscWarsTrace(
            'DeferredPushPermissionCoordinator._offerIfNeeded skip '
            'source=$source reason=no_completed_sessions count=$n',
          );
          return;
        }
      }
      // Don't show the education sheet if we can't act today (daily system prompt cap),
      // or if the OS state is already "denied" (user must enable in Settings).
      final status =
          await BattleMessagingService.notificationAuthorizationStatus();
      upscWarsTrace(
        'DeferredPushPermissionCoordinator._offerIfNeeded os_status '
        'source=$source status=$status',
      );
      if (BattleMessagingService.notificationAuthorizationAllowsPush(status)) {
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded skip '
          'source=$source reason=already_enabled',
        );
        return;
      }
      if (status == AuthorizationStatus.denied) {
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded skip '
          'source=$source reason=os_denied',
        );
        return;
      }
      if (status == AuthorizationStatus.notDetermined) {
        final svc = await ref.read(prefsServiceProvider.future);
        final lastMs = svc.pushSystemPromptLastShownAtMs;
        if (lastMs != null) {
          final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
          final canPromptToday =
              DateTime.now().difference(last) >= const Duration(hours: 24);
          if (!canPromptToday) {
            upscWarsTrace(
              'DeferredPushPermissionCoordinator._offerIfNeeded skip '
              'source=$source reason=daily_cap lastMs=$lastMs',
            );
            return;
          }
        }
      }
      if (_offerInFlight) {
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded skip '
          'source=$source reason=offer_in_flight',
        );
        return;
      }
      _offerInFlight = true;
      try {
        if (!context.mounted) return;
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded showing_sheet '
          'source=$source',
        );
        final wantSystemPrompt = await showDeferredPushPermissionSheet(context);
        upscWarsTrace(
          'DeferredPushPermissionCoordinator._offerIfNeeded sheet_result '
          'source=$source wantSystemPrompt=$wantSystemPrompt',
        );
        if (!context.mounted) return;
        final svc = await ref.read(prefsServiceProvider.future);
        svc.deferredPushModalShownCountV2 =
            svc.deferredPushModalShownCountV2 + 1;
        final modalIndex = svc.deferredPushModalShownCountV2;
        unawaited(
          Analytics.track(
            ref,
            DeferredPushEducationModalOutcomeEvent(
              source: source,
              modalIndex: modalIndex,
              tappedEnableNotifications: wantSystemPrompt == true,
            ),
          ),
        );
        if (wantSystemPrompt == true) {
          await PushNotificationsEnsureService.ensureEnabled(
            context,
            ref,
            source: source,
            allowEducationSheet: false,
          );
        }
      } finally {
        _offerInFlight = false;
      }
    } catch (e, st) {
      upscWarsTrace(
        'DeferredPushPermissionCoordinator._offerIfNeeded '
        '(requireCompletedSession=$requireCompletedSession, source=$source)',
        error: e,
        stackTrace: st,
      );
    }
  }
}
