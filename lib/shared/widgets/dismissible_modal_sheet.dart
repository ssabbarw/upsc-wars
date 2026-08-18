import 'package:flutter/material.dart';

/// Lets taps on the dimmed area dismiss a scroll-controlled transparent sheet.
///
/// [showModalBottomSheet] with [isScrollControlled] and a transparent
/// background gives the builder the full screen. An [Align] then expands to
/// that size, so Flutter's barrier never receives the tap. Wrap the sheet
/// content with this; empty space above a bottom-aligned card passes through
/// to the scrim.
class DismissOnScrimTap extends StatelessWidget {
  const DismissOnScrimTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        child,
      ],
    );
  }
}
