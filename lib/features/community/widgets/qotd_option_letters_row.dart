import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/extensions/context_extensions.dart';

/// A/B/C/D row for QOTD: after a pick, all buttons are disabled; correct, wrong pick,
/// and other options stay visually distinct.
class QotdOptionLettersRow extends StatelessWidget {
  const QotdOptionLettersRow({
    super.key,
    required this.correctOption,
    required this.picked,
    required this.onPick,
    this.busy = false,
  });

  final String correctOption;
  final String? picked;
  final ValueChanged<String> onPick;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final correct = correctOption.toLowerCase().trim();
    final pick = picked?.toLowerCase().trim();
    final revealed = pick != null && pick.isNotEmpty;

    Widget cell(String key) {
      final label = key.toUpperCase();
      final isCorrectKey = correct == key;
      final isUserPick = pick == key;

      Color bg;
      Color border;
      Color fg;
      double borderW = 1;

      if (!revealed) {
        bg = scheme.surface;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        fg = scheme.onSurface;
      } else if (isCorrectKey) {
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        border = AppColors.correct;
        fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
        borderW = 2;
      } else if (isUserPick && !isCorrectKey) {
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        border = AppColors.wrong;
        fg = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
        borderW = 2;
      } else {
        bg = isDark
            ? AppColors.surfaceTertiaryDark
            : AppColors.surfaceTertiaryLight;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        fg = scheme.onSurfaceVariant;
        borderW = 1.5;
      }

      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: (revealed || busy) ? null : () => onPick(key),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border, width: borderW),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.label().copyWith(color: fg),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: cell('a')),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: cell('b')),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: cell('c')),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: cell('d')),
      ],
    );
  }
}
