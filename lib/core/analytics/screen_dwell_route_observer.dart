import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/analytics_provider.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// **Named** routes to measure with [ScreenDwellRouteObserver] (root navigator).
/// Main tabs (home, history, …) use [ScreenFlow] shell tab dwell; paywall
/// (later) add here.
const Set<String> kScreenDwellTrackedNames = {
  'onboarding',
  'subject_test',
  'topic_test',
  'test_session',
  'battle_test',
  'session_results',
  'battle_results',
  'danger_zone_review',
  'revision_queue',
  'revision_queue_session',
  'qotd_post',
  'qotd_explanation',
  'open_challenge_pick_subject',
  'open_challenge_detail',
  'community_connect',
  'bookmarks',
};

class _Dwell {
  int accumulatedMs = 0;
  int? segmentStartMs;

  void pause(int now) {
    if (segmentStartMs == null) return;
    accumulatedMs += now - segmentStartMs!;
    segmentStartMs = null;
  }

  void startSegment(int now) {
    segmentStartMs = now;
  }

  int totalMsAt(int now) {
    if (segmentStartMs == null) return accumulatedMs;
    return accumulatedMs + (now - segmentStartMs!);
  }
}

/// [NavigatorObserver] for [kScreenDwellTrackedNames]: accumulates dwell while
/// the route is **top**; **pauses** when another route is pushed on top and
/// **resumes** on pop. Emits [ScreenDwellEndedEvent] when a tracked route is
/// finished (pop / remove / replace).
class ScreenDwellRouteObserver extends NavigatorObserver {
  ScreenDwellRouteObserver(this._ref);

  final Ref _ref;
  final Map<Route<dynamic>, _Dwell> _byRoute = {};

  AnalyticsService get _analytics => _ref.read(analyticsServiceProvider);

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  void _emitDwellEnd(String name, int durationMs, String endKind) {
    if (durationMs < 0) return;
    unawaited(
      _analytics.track(
        ScreenDwellEndedEvent(
          screenName: name,
          durationMs: durationMs,
          endKind: endKind,
        ),
      ),
    );
  }

  static bool isTrackedName(String? n) =>
      n != null && n.isNotEmpty && kScreenDwellTrackedNames.contains(n);

  static bool isTracked(Route<dynamic>? route) {
    if (route == null) return false;
    return isTrackedName(route.settings.name);
  }

  String? _name(Route<dynamic> r) => r.settings.name;

  void _pauseFor(Route<dynamic> route) {
    if (!isTracked(route)) return;
    _byRoute.putIfAbsent(route, _Dwell.new);
    _byRoute[route]!.pause(_nowMs());
  }

  void _removeRoute(Route<dynamic> route, String endKind) {
    if (!isTracked(route)) return;
    final name = _name(route);
    if (name == null) return;
    final w = _byRoute.remove(route);
    if (w == null) return; // e.g. already ended via another observer call
    final ms = w.totalMsAt(_nowMs());
    _emitDwellEnd(name, ms, endKind);
  }

  void _resumeFor(Route<dynamic> route) {
    if (!isTracked(route)) return;
    _byRoute.putIfAbsent(route, _Dwell.new);
    _byRoute[route]!.startSegment(_nowMs());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && isTracked(previousRoute)) {
      _pauseFor(previousRoute);
    }
    if (isTracked(route) && !_byRoute.containsKey(route)) {
      _byRoute[route] = _Dwell()..startSegment(_nowMs());
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeRoute(route, 'back_pop');
    if (previousRoute != null && isTracked(previousRoute)) {
      _resumeFor(previousRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeRoute(route, 'removed');
    if (previousRoute != null && isTracked(previousRoute)) {
      _resumeFor(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _removeRoute(oldRoute, 'replaced');
    }
    if (newRoute != null && isTracked(newRoute) && !_byRoute.containsKey(newRoute)) {
      _byRoute[newRoute] = _Dwell()..startSegment(_nowMs());
    }
  }
}
