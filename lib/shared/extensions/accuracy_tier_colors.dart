import 'package:flutter/material.dart';

import '../../core/domain/entities/accuracy_display_tier.dart';
import '../../core/theme/app_colors.dart';

extension AccuracyDisplayTierColors on AccuracyDisplayTier {
  Color resolveAccuracyForeground(BuildContext context) {
    switch (this) {
      case AccuracyDisplayTier.dash:
      case AccuracyDisplayTier.mutedLowAttempts:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case AccuracyDisplayTier.high:
        return AppColors.correct;
      case AccuracyDisplayTier.medium:
        return AppColors.warning;
      case AccuracyDisplayTier.low:
        return AppColors.wrong;
    }
  }
}
