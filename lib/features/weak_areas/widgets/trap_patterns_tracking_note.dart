import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Why trap counts exist — shown above the catalog on [TrapPatternsScreen].
class TrapPatternsTrackingNote extends StatelessWidget {
  const TrapPatternsTrackingNote({super.key});

  static const message =
      'We keep track of which traps catch you most, so you can watch for them in the exam.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final fg = isDark ? AppColors.infoTextDark : AppColors.infoText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySm().copyWith(color: fg, height: 1.4),
      ),
    );
  }
}
