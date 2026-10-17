import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Small "PYQ 2023" tag shown above previous-year UPSC questions.
class PyqBadge extends StatelessWidget {
  const PyqBadge({super.key, this.year});

  final int? year;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = year == null ? 'PYQ' : 'PYQ $year';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm().copyWith(
          color: isDark ? AppColors.infoTextDark : AppColors.infoText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
