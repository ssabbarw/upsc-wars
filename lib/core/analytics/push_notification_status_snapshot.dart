import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'analytics.dart';
import 'analytics_events.dart';
import '../services/battle_messaging_service.dart';

DateTime? _lastPushStatusSnapshot;

/// Fires [PushNotificationStatusSnapshotEvent] (debounced to avoid
/// back-to-back duplicates on cold start when [AppOpened] and [resumed] run).
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
