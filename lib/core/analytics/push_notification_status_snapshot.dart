import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'analytics.dart';
import 'analytics_events.dart';
import '../services/battle_messaging_service.dart';

DateTime? _lastPushStatusSnapshot;

/// Fires [PushNotificationStatusSnapshotEvent] — **OS push permission
/// snapshot** (not in-app settings toggles) — and updates the GA4 user
/// property `push_alerts` in [FirebaseAnalyticsSink] (see event class docs).
/// **Debounced** to avoid back-to-back duplicates on cold start when
/// [AppOpenedEvent] and [SessionStartedEvent] both run close together.
Future<void> trackPushNotificationStatusSnapshot(WidgetRef ref) async {
  final now = DateTime.now();
  if (_lastPushStatusSnapshot != null &&
      now.difference(_lastPushStatusSnapshot!) <
          const Duration(milliseconds: 900)) {
    return;
  }
  _lastPushStatusSnapshot = now;
  final s = await BattleMessagingService.notificationAuthorizationStatus();
  final status = BattleMessagingService.notificationAuthorizationStatusLabel(s);
  final allows = BattleMessagingService.notificationAuthorizationAllowsPush(s);
  await Analytics.track(
    ref,
    PushNotificationStatusSnapshotEvent(status: status, allowsPush: allows),
  );
}
