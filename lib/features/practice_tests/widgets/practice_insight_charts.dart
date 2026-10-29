import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../domain/practice_subject_insights.dart';

Color insightBandColor(InsightBand band, {required bool isDark}) {
  switch (band) {
    case InsightBand.bad:
      return isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    case InsightBand.mixed:
      return isDark ? AppColors.warningTextDark : AppColors.warningText;
    case InsightBand.good:
      return isDark ? AppColors.correctTextDark : AppColors.correctText;
    case InsightBand.thin:
      return isDark ? AppColors.gray200 : AppColors.gray600;
  }
}

Color insightBandFill(InsightBand band, {required bool isDark}) {
  switch (band) {
    case InsightBand.bad:
      return isDark
          ? AppColors.wrongBgDark.withValues(alpha: 0.55)
          : AppColors.wrongBg;
    case InsightBand.mixed:
      return isDark
          ? AppColors.warningBgDark.withValues(alpha: 0.55)
          : AppColors.warningBg;
    case InsightBand.good:
      return isDark
          ? AppColors.correctBgDark.withValues(alpha: 0.55)
          : AppColors.correctBg;
    case InsightBand.thin:
      return isDark
          ? AppColors.surfaceTertiaryDark
          : AppColors.surfaceTertiaryLight;
  }
}

/// Horizontal stacked bar: green = right, red = wrong.
class InsightSplitBar extends StatelessWidget {
  const InsightSplitBar({
    super.key,
    required this.correct,
    required this.wrong,
    this.height = 12,
  });

  final int correct;
  final int wrong;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = correct + wrong;
    final rightShare = total == 0 ? 0.0 : correct / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: rightShare),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Row(
                children: [
                  if (value > 0)
                    Expanded(
                      flex: math.max(1, (value * 1000).round()),
                      child: const ColoredBox(color: AppColors.primary),
                    ),
                  if (total > 0 && value < 1)
                    Expanded(
                      flex: math.max(1, ((1 - value) * 1000).round()),
                      child: const ColoredBox(color: AppColors.wrong),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
