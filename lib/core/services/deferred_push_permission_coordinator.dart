import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/shared/widgets/deferred_push_permission_sheet.dart';

/// Defers the system notification prompt until the user has completed a test
/// or signed in from the Community tab.
class DeferredPushPermissionCoordinator {
  DeferredPushPermissionCoordinator._();

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
  static Future<void> onSignedInAfterCommunityPromptArmed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!_takeCommunitySignInArmed()) return;
    await _offerIfNeeded(context, ref, requireCompletedSession: false);
  }

  /// Results screen: offer once the user has at least one completed session.
  static Future<void> onResultsScreenMounted(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _offerIfNeeded(context, ref, requireCompletedSession: true);
  }

  static Future<void> _offerIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    required bool requireCompletedSession,
  }) async {
    if (kIsWeb) return;
    final prefs = await ref.read(prefsServiceProvider.future);
    if (prefs.deferredPushPermissionSheetCompletedV1) return;
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
      svc.deferredPushPermissionSheetCompletedV1 = true;
      ref.invalidate(prefsServiceProvider);
      if (wantSystemPrompt == true) {
        await BattleMessagingService.requestPushAuthorizationAndSync();
      }
    } finally {
      _offerInFlight = false;
    }
  }
}
