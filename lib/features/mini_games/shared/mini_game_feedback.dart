import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Correct/wrong reveal banner — pops in for correct, shakes for wrong.
class MiniGameResultBanner extends StatelessWidget {
  const MiniGameResultBanner({
    super.key,
    required this.correct,
    required this.text,
    this.center = false,
  });

  final bool correct;
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.correct : AppColors.wrong;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(
          correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.label().copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final aligned = center ? Center(child: content) : content;

    return TweenAnimationBuilder<double>(
      key: ValueKey('$correct-$text'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: correct ? 450 : 500),
      curve: correct ? Curves.easeOutBack : Curves.easeOut,
      builder: (context, t, child) {
        final dx =
            correct ? 0.0 : math.sin(t * math.pi * 5) * (1 - t) * 10;
        final scale = correct ? (0.6 + 0.4 * t) : 1.0;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: aligned,
    );
  }
}
