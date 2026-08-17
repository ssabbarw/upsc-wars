import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'analytics_events.dart';
import '../providers/analytics_provider.dart';

/// Admin / editor / about surfaces — skip for growth analytics volume.
const Set<String> kScreenViewIgnoredNames = {
  'admin_dashboard',
  'feature_health',
  'spot_composer',
  'question_editor',
  'question_editor_edit',
  'question_editor_preview',
  'daily_ca_review',
  'daily_ca_review_edit',
  'about_us',
};

/// Subscribes to the navigator: when a route is pushed or replaced, emits
/// [ScreenViewedEvent] (GA4: `screen_viewed`, parameter `screen_name`) if the
/// [RouteSettings.name] is set and not in [kScreenViewIgnoredNames].
/// [GoRoute.name] in [app_router] must be set for each screen you want in
/// analytics.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._ref);

  final Ref _ref;

  void _emit(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    if (kScreenViewIgnoredNames.contains(name)) return;
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
