import 'package:flutter/material.dart';

import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

/// Exam / Learning picker — same visuals as [TestConfigBottomSheet].
class TestConfigModeOptionCard extends StatelessWidget {
  const TestConfigModeOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.examStyle,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool examStyle;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bg;
    late final Color border;
    late final Color titleColor;
    late final Color bodyColor;
    late final Color iconColor;

    if (selected) {
      if (examStyle) {
        bg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
        border = AppColors.info;
        titleColor = isDark ? AppColors.infoTextDark : AppColors.infoText;
        bodyColor = titleColor;
        iconColor = titleColor;
      } else {
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        titleColor = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        bodyColor = titleColor;
        iconColor = titleColor;
        border = AppColors.primary;
      }
    } else {
      bg = scheme.surface;
      border = borderColor;
      titleColor = scheme.onSurface;
      bodyColor = scheme.onSurfaceVariant;
      iconColor = scheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: selected ? 2 : 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.labelSm().copyWith(color: titleColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTextStyles.caption().copyWith(color: bodyColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// 45s / 1 min / 2 min row — same as in-app learning config.
class TestConfigLearningTimeTile extends StatelessWidget {
  const TestConfigLearningTimeTile({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? (isDark ? AppColors.primaryDeep : AppColors.primaryLight)
        : scheme.surface;
    final fg = selected
        ? (isDark ? AppColors.onPrimary : AppColors.primaryDeep)
        : scheme.onSurface;
    final border = selected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected ? 2 : 0.5),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm().copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}
