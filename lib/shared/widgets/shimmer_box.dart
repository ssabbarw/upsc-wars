import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A pulsing placeholder box used in skeleton loading states.
///
/// Animates opacity between 40 % and 100 %. Defaults to the theme's
/// [ColorScheme.surfaceContainerLow]; pass [color] to override (e.g. dark
/// Daily War surfaces).
class ShimmerBox extends HookWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 6,
    this.color,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    final opacity = useAnimation(
      Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)),
    );

    final color =
        this.color ?? Theme.of(context).colorScheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) => Opacity(
        opacity: opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
