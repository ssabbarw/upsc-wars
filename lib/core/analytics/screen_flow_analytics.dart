import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/analytics_provider.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// [ScreenDwellEndedEvent] / [ScreenFlowActionEvent] for **modals and shell
/// tabs** (the root [ScreenDwellRouteObserver] only sees named [Route]s).
///
/// [screen name constants] are aligned with [GoRoute.name] where that exists
/// and short ids for pre-route surfaces (e.g. push permission sheet).
abstract final class ScreenFlow {
  const ScreenFlow._();

  // Modal / non-GoRoute surfaces
  static const String deferredPushPrePrompt = 'deferred_push_pre_prompt';

  // Critical screens (when logging actions without a route, match GoRoute.name)
  static const String onboarding = 'onboarding';
  static const String testSession = 'test_session';
  static const String sessionResults = 'session_results';
  static const String dangerZoneReview = 'danger_zone_review';
  static const String revisionQueue = 'revision_queue';
  static const String battleResults = 'battle_results';

  static List<String> shellTabNames({required bool hasCommunity}) => hasCommunity
      ? const ['home', 'history', 'progress', 'community']
      : const ['home', 'history', 'progress'];

  static Future<void> logShellTabDwellEnded(
    WidgetRef ref, {
    required int fromIndex,
    required int durationMs,
    required bool hasCommunity,
  }) async {
    final names = shellTabNames(hasCommunity: hasCommunity);
    if (fromIndex < 0 || fromIndex >= names.length) return;
    if (durationMs < 0) return;
    await ref.read(analyticsServiceProvider).track(
          ScreenDwellEndedEvent(
            screenName: names[fromIndex],
            durationMs: durationMs,
            endKind: 'shell_tab_change',
          ),
        );
  }

  static void logAction(
    WidgetRef ref, {
    required String screenName,
    required String actionId,
    String actionKind = 'cta',
  }) {
    unawaited(
      _track(
        ref.read(analyticsServiceProvider),
        screenName: screenName,
        actionId: actionId,
        actionKind: actionKind,
      ),
    );
  }

  static void logActionForServices(
    AnalyticsService analytics, {
    required String screenName,
    required String actionId,
    String actionKind = 'cta',
  }) {
    unawaited(
      _track(
        analytics,
        screenName: screenName,
        actionId: actionId,
        actionKind: actionKind,
      ),
    );
  }

  static Future<void> _track(
    AnalyticsService analytics, {
    required String screenName,
    required String actionId,
    required String actionKind,
  }) {
    return analytics.track(
      ScreenFlowActionEvent(
        screenName: screenName,
        actionId: actionId,
        actionKind: actionKind,
      ),
    );
  }
}
