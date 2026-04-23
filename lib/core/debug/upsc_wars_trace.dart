// ignore_for_file: avoid_print

import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

/// Hard-to-miss diagnostics: [print] is not throttled like [debugPrint], shows
/// in `flutter run`, Android `adb logcat`, and Xcode device logs.
void upscWarsTrace(String message, {Object? error, StackTrace? stackTrace}) {
  final ts = DateTime.now().toUtc().toIso8601String();
  const p = '[UpscWars TRACE]';
  print('$p $ts $message');
  if (error != null) {
    print('$p $ts error: $error');
  }
  if (stackTrace != null) {
    print('$p $ts stack:\n$stackTrace');
  }
  developer.log(
    message,
    name: 'UpscWars',
    error: error,
    stackTrace: stackTrace,
    time: DateTime.now(),
  );
}

/// Prints every root [Navigator] push/pop/replace (helps when the UI is blank
/// but no Dart exception is thrown).
final class UpscWarsRouteTraceObserver extends NavigatorObserver {
  void _line(String verb, Route<dynamic> route) {
    final s = route.settings;
    upscWarsTrace(
      'Navigator.$verb name=${s.name} arguments=${s.arguments} '
      'type=${route.runtimeType}',
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _line('didPush', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _line('didPop', route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _line('didRemove', route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _line('didReplace(new)', newRoute);
    }
  }
}
