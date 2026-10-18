import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';

/// Why trap counts exist — shown above the catalog on [TrapPatternsScreen].
class TrapPatternsTrackingNote extends StatelessWidget {
  const TrapPatternsTrackingNote({super.key});

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
        context.l10n.trapsTrackingNote,
        style: AppTextStyles.bodySm().copyWith(color: fg, height: 1.4),
      ),
    );
  }
}
