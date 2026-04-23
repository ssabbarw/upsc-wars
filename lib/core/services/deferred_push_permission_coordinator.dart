import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/debug/upsc_wars_trace.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
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
  static void armCommunitySignInPrompt() => _communitySignInArmed = true;

  /// Clears an armed community prompt (e.g. sign-in cancelled or failed).
  static void clearCommunitySignInArmed() => _communitySignInArmed = false;

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
    if (!_takeCommunitySignInArmed()) return;
    onSignedInFromCommunityTab?.call();
    await _offerIfNeeded(context, ref, requireCompletedSession: false);
  }

  /// After a completed test: offer the notification education sheet from explicit
  /// user actions only (e.g. Go back / Home, Review explanations), not on mount.
  static Future<void> tryOfferFromResultsUserAction(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _offerIfNeeded(context, ref, requireCompletedSession: true);
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
  }) async {
    if (kIsWeb) return;
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      if (prefs.deferredPushPermissionSheetCompletedV1) return;
      if (prefs.deferredPushModalShownCountV2 >= _maxEducationModals) return;

      if (requireCompletedSession) {
        final db = ref.read(userDatabaseProvider);
        final n = await db.sessionsDao.countCompletedSessions();
        if (n < 1) return;
      }
      if (_offerInFlight) return;
      _offerInFlight = true;
      try {
        if (!context.mounted) return;
        final wantSystemPrompt = await showDeferredPushPermissionSheet(context);
        if (!context.mounted) return;
        final svc = await ref.read(prefsServiceProvider.future);
        svc.deferredPushModalShownCountV2 = svc.deferredPushModalShownCountV2 + 1;
        if (wantSystemPrompt == true) {
          await BattleMessagingService.requestPushAuthorizationAndSync();
        }
      } finally {
        _offerInFlight = false;
      }
    } catch (e, st) {
      upscWarsTrace(
        'DeferredPushPermissionCoordinator._offerIfNeeded '
        '(requireCompletedSession=$requireCompletedSession)',
        error: e,
        stackTrace: st,
      );
    }
  }
}
