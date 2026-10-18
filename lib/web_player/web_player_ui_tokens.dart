import 'package:flutter/material.dart';

import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

/// Web player UI aligned with [AppTheme] primary CTAs, outlines, and chips.
abstract final class WebPlayerUiTokens {
  /// Primary green CTA — same padding, radius, type as app [elevatedButtonTheme].
  static ButtonStyle primaryCta(BuildContext context) {
    final base = Theme.of(context).elevatedButtonTheme.style;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 48)),
      textStyle: WidgetStatePropertyAll(AppTextStyles.label()),
      foregroundColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(AppColors.transparent),
    ).merge(base ?? const ButtonStyle());
  }

  /// Red submit / destructive CTA (exam toolbar, palette).
  static ButtonStyle destructiveCta(
    BuildContext context, {
    required bool isDark,
    required ColorScheme scheme,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: AppColors.transparent,
      backgroundColor: isDark ? scheme.errorContainer : AppColors.wrong,
      foregroundColor: isDark ? scheme.onErrorContainer : AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppTextStyles.label(),
    );
  }

  /// Compact icon grid button — inherits app outline theme + square hit target.
  static ButtonStyle outlineIconSquare(BuildContext context) {
    final base = Theme.of(context).outlinedButtonTheme.style;
    return OutlinedButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ).merge(base ?? const ButtonStyle());
  }

  /// Full-width outline (e.g. Go back in palette).
  static ButtonStyle outlineFullWidth(BuildContext context) {
    final base = Theme.of(context).outlinedButtonTheme.style;
    return OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppTextStyles.label(),
    ).merge(base ?? const ButtonStyle());
  }

  /// [SegmentedButton] track — selected segment uses primary / primaryLight like app.
  static ButtonStyle segmented(BuildContext context, {required bool isDark}) {
    return ButtonStyle(
      visualDensity: VisualDensity.standard,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      textStyle: WidgetStatePropertyAll(AppTextStyles.labelSm()),
      side: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return BorderSide(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: selected ? 1.2 : 0.5,
        );
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? AppColors.correctTextDark : AppColors.primaryDeep;
        }
        return Theme.of(context).colorScheme.onSurface;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark
              ? AppColors.primaryDark.withValues(alpha: 0.45)
              : AppColors.primaryLight;
        }
        return Theme.of(context).colorScheme.surface;
      }),
    );
  }

  /// Time preset chips — DM Sans label, primary when selected.
  static Widget timeChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required bool isDark,
  }) {
    return FilterChip(
      label: Text(label, style: AppTextStyles.labelSm()),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: isDark
          ? AppColors.primaryDark.withValues(alpha: 0.5)
          : AppColors.primaryLight,
      backgroundColor: isDark
          ? AppColors.surfaceSecondaryDark
          : AppColors.surfacePrimaryLight,
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
        width: selected ? 1.2 : 0.5,
      ),
      labelStyle: AppTextStyles.labelSm().copyWith(
        color: selected
            ? (isDark ? AppColors.correctTextDark : AppColors.primaryDeep)
            : Theme.of(context).colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}
