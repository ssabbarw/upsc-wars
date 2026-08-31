import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'analytics.dart';
import 'analytics_events.dart';
import 'activation_milestones.dart';
import 'push_notification_status_snapshot.dart';
import 'session_entry_source.dart';

/// Maps app foreground/background to coarse session boundaries.
class AnalyticsAppLifecycleObserver extends WidgetsBindingObserver {
  AnalyticsAppLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Brief delay so push / deep-link handlers can set [SessionEntrySource]
      // before we attribute this foreground session.
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final entry = SessionEntrySource.consume();
        await Analytics.track(
          _ref,
          SessionStartedEvent(
            entrySource: entry.source,
            entryDetail: entry.detail,
          ),
        );
        unawaited(maybeLogReturnAfterDemo(_ref));
      }());
      unawaited(trackPushNotificationStatusSnapshot(_ref));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(Analytics.track(_ref, const SessionEndedEvent()));
    }
  }
}
