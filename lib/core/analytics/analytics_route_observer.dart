import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'analytics_events.dart';
import '../providers/analytics_provider.dart';

/// Subscribes to the navigator: when a route is pushed or replaced, emits
/// [ScreenViewedEvent] (GA4: `screen_viewed`, parameter `screen_name`) if the
/// [RouteSettings.name] is set. [GoRoute.name] in [app_router] must be set
/// for each screen you want in analytics.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._ref);

  final Ref _ref;

  void _emit(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    unawaited(
      _ref.read(analyticsServiceProvider).track(
            ScreenViewedEvent(screenName: name),
          ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _emit(newRoute);
  }
}
