import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// Phones stay portrait; tablets and the opened iPhone Duo inner display can
/// rotate. Keyed on the window's shortest side so it doesn't flip on rotation,
/// and re-applied when the window changes (Duo fold/unfold).
abstract final class OrientationPolicy {
  static bool? _applied;

  static bool allowsRotation(double shortestSide) =>
      shortestSide >= AppBreakpoints.tablet;

  static Future<void> apply(double shortestSide) {
    final allow = allowsRotation(shortestSide);
    if (allow == _applied) return Future.value();
    final wasUnset = _applied == null;
    _applied = allow;
    // Info.plist / manifest already allow every orientation, so there is
    // nothing to unlock. Asking anyway makes iPadOS log UISceneErrorDomain 101
    // in windowed mode.
    if (allow && wasUnset) return Future.value();
    return SystemChrome.setPreferredOrientations(
      allow ? const [] : const [DeviceOrientation.portraitUp],
    );
  }

  /// Before `runApp`, from the first view's logical size.
  static Future<void> applyForInitialView() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return apply(0);
    final view = views.first;
    return apply((view.physicalSize / view.devicePixelRatio).shortestSide);
  }
}

class OrientationPolicyHost extends HookWidget {
  const OrientationPolicyHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final allow = OrientationPolicy.allowsRotation(shortestSide);
    useEffect(() {
      unawaited(OrientationPolicy.apply(shortestSide));
      return null;
    }, [allow]);
    return child;
  }
}
