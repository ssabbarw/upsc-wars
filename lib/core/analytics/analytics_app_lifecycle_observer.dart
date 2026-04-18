import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'analytics.dart';
import 'analytics_events.dart';

/// Maps app foreground/background to coarse session boundaries.
class AnalyticsAppLifecycleObserver extends WidgetsBindingObserver {
  AnalyticsAppLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(Analytics.track(_ref, const SessionStartedEvent()));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(Analytics.track(_ref, const SessionEndedEvent()));
    }
  }
}
