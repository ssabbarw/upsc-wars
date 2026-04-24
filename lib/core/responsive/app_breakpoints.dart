import 'package:flutter/material.dart';

/// Width thresholds for responsive layouts.
abstract final class AppBreakpoints {
  /// Small tablet and above (600px+): switch to NavigationRail, wider cards.
  static const double tablet = 600;

  /// Large tablet (900px+): extend NavigationRail labels, two-column test layout.
  static const double largeTablet = 900;

  /// Returns grid column count based on available layout width from LayoutBuilder.
  static int gridColumns(double availableWidth) {
    if (availableWidth >= 750) return 4;
    if (availableWidth >= 520) return 3;
    return 2;
  }

  /// Horizontal padding to center content on push-route screens (full-screen).
  /// Shell-branch screens (Home, History, Progress) are already narrowed by the
  /// NavigationRail and should not use this.
  static EdgeInsets fullScreenHPadding(double screenWidth) {
    if (screenWidth >= 1100) {
      return EdgeInsets.symmetric(horizontal: (screenWidth - 1000) / 2);
    }
    if (screenWidth >= 720) {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
    return EdgeInsets.zero;
  }
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isTablet => MediaQuery.sizeOf(this).width >= AppBreakpoints.tablet;
  bool get isLargeTablet =>
      MediaQuery.sizeOf(this).width >= AppBreakpoints.largeTablet;
}
