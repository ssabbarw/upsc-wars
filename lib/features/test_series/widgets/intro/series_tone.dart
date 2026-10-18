import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Colour families used to give each section of the intro its own identity.
enum SeriesTone { green, blue, amber, red, purple }

/// Accent (icons, bars), tinted background and readable text colour of a
/// [SeriesTone], for the current brightness.
class SeriesToneColors {
  const SeriesToneColors({
    required this.accent,
    required this.bg,
    required this.fg,
  });

  final Color accent;
  final Color bg;
  final Color fg;
}

SeriesToneColors seriesToneColors(SeriesTone tone, {required bool isDark}) {
  switch (tone) {
    case SeriesTone.green:
      return SeriesToneColors(
        accent: AppColors.primary,
        bg: isDark ? AppColors.correctBgDark : AppColors.correctBg,
        fg: isDark ? AppColors.correctTextDark : AppColors.correctText,
      );
    case SeriesTone.blue:
      return SeriesToneColors(
        accent: AppColors.info,
        bg: isDark ? AppColors.infoBgDark : AppColors.infoBg,
        fg: isDark ? AppColors.infoTextDark : AppColors.infoText,
      );
    case SeriesTone.amber:
      return SeriesToneColors(
        accent: AppColors.warning,
        bg: isDark ? AppColors.warningBgDark : AppColors.warningBg,
        fg: isDark ? AppColors.warningTextDark : AppColors.warningText,
      );
    case SeriesTone.red:
      return SeriesToneColors(
        accent: AppColors.wrong,
        bg: isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
        fg: isDark ? AppColors.wrongTextDark : AppColors.wrongText,
      );
    case SeriesTone.purple:
      return SeriesToneColors(
        accent: AppColors.purple,
        bg: isDark ? AppColors.purpleBgDark : AppColors.purpleBg,
        fg: isDark ? AppColors.purpleTextDark : AppColors.purpleText,
      );
  }
}

/// Card surface: either the plain themed surface, or tinted by [tone].
BoxDecoration introCardDecoration(BuildContext context, {SeriesTone? tone}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = tone == null ? null : seriesToneColors(tone, isDark: isDark);
  return BoxDecoration(
    color: colors?.bg ?? Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(
      color: colors == null
          ? (isDark ? AppColors.borderDark : AppColors.borderLight)
          : colors.accent.withValues(alpha: 0.25),
      width: 0.8,
    ),
  );
}

/// Rounded square with a tinted background and an accent icon.
class ToneIconBadge extends StatelessWidget {
  const ToneIconBadge({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 40,
  });

  final IconData icon;
  final SeriesTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = seriesToneColors(tone, isDark: isDark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.55, color: c.accent),
    );
  }
}

/// Small rounded label: "Wrong", "English + हिन्दी", "Sample".
class TonePill extends StatelessWidget {
  const TonePill({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final SeriesTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = seriesToneColors(tone, isDark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.accent.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.accent),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSm().copyWith(
                color: c.fg,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with an optional muted subtitle.
class IntroSectionTitle extends StatelessWidget {
  const IntroSectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.bodySm().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
