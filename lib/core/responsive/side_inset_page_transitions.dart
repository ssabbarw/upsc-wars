import 'package:flutter/material.dart';

/// Page name of the tab shell. Its Duo rail lives in the side inset, so the
/// shell page is left unpadded.
const appShellPageName = 'app-shell';

/// Keeps every pushed page out of the left/right safe area (iPhone Duo's
/// status/tab column). Wraps the platform's default transition so animations
/// and iOS swipe-back behave as before.
class SideInsetPageTransitionsBuilder extends PageTransitionsBuilder {
  const SideInsetPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  static PageTransitionsTheme theme() {
    const defaults = PageTransitionsTheme();
    return PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: SideInsetPageTransitionsBuilder(
            defaults.builders[platform] ?? const ZoomPageTransitionsBuilder(),
          ),
      },
    );
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final page = route.settings.name == appShellPageName
        ? child
        : _SideInsetPadding(child: child);
    return inner.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      page,
    );
  }
}

class _SideInsetPadding extends StatelessWidget {
  const _SideInsetPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    if (padding.left == 0 && padding.right == 0) return child;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(top: false, bottom: false, child: child),
    );
  }
}
