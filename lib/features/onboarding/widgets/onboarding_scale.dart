import 'package:flutter/material.dart';

/// Scale vs ~390dp shortest side.
///
/// No upward bias: oversizing makes content taller than the viewport, which
/// forces [OnboardingFit] to shrink the whole layout and waste side margins.
double onboardingScale(BuildContext context) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  return (shortest / 390).clamp(0.9, 1.3);
}

double onb(BuildContext context, double designPx) =>
    designPx * onboardingScale(context);

/// Shrinks [child] to fit the available box — never scrolls.
///
/// Child should be intrinsically sized (no [Expanded]/[Spacer] inside).
class OnboardingFit extends StatelessWidget {
  const OnboardingFit({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
        );
      },
    );
  }
}
