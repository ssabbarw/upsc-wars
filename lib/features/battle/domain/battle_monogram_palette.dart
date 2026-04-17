import 'package:flutter/material.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';

/// Pleasant tints for match-preview monograms; pick per battle via [sessionId].
Color battleMatchMonogramBackground(String sessionId, String salt) {
  const palette = <Color>[
    AppColors.primaryLight,
    AppColors.infoBg,
    AppColors.correctBg,
    AppColors.warningBg,
    AppColors.gray100,
    AppColors.surfaceTertiaryLight,
  ];
  final i = ('$sessionId$salt').hashCode.abs() % palette.length;
  return palette[i];
}

Color battleMatchMonogramForeground(Color background) {
  return background.computeLuminance() > 0.72
      ? AppColors.onSurfaceLight
      : AppColors.onPrimary;
}
