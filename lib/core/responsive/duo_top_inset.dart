import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// When iPhone Duo moves the status bar into a side column, the system top
/// inset drops to ~0 and content hits the rounded display corner. Give every
/// SafeArea / AppBar a minimum top inset in that pose.
class DuoTopInset extends StatelessWidget {
  const DuoTopInset({super.key, required this.child});

  static const _sideChromeMin = 40.0;
  static const _minTop = 24.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final side = math.max(data.viewPadding.left, data.viewPadding.right);
    if (side < _sideChromeMin || data.viewPadding.top >= _minTop) return child;
    return MediaQuery(
      data: data.copyWith(
        padding: data.padding.copyWith(
          top: math.max(data.padding.top, _minTop),
        ),
        viewPadding: data.viewPadding.copyWith(top: _minTop),
      ),
      child: child,
    );
  }
}
