import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Icon + accent for a trap type, so list rows are scannable at a glance.
class TrapPatternVisual {
  const TrapPatternVisual({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  static TrapPatternVisual of(String trapType) {
    return _byType[trapType] ?? _fallback;
  }

  static const _fallback = TrapPatternVisual(
    icon: Icons.psychology_alt_rounded,
    accent: AppColors.primary,
  );

  static const _byType = <String, TrapPatternVisual>{
    'entity-swap': TrapPatternVisual(
      icon: Icons.switch_account_rounded,
      accent: AppColors.info,
    ),
    'scope-extension': TrapPatternVisual(
      icon: Icons.zoom_out_map_rounded,
      accent: AppColors.warning,
    ),
    'conflation': TrapPatternVisual(
      icon: Icons.merge_type_rounded,
      accent: AppColors.primary,
    ),
    'temporal-swap': TrapPatternVisual(
      icon: Icons.history_rounded,
      accent: AppColors.info,
    ),
    'partial-truth': TrapPatternVisual(
      icon: Icons.fact_check_rounded,
      accent: AppColors.warning,
    ),
    'reversed-causation': TrapPatternVisual(
      icon: Icons.swap_vert_rounded,
      accent: AppColors.wrong,
    ),
    'plausible-fabrication': TrapPatternVisual(
      icon: Icons.auto_awesome_rounded,
      accent: AppColors.warning,
    ),
    'geographic-swap': TrapPatternVisual(
      icon: Icons.wrong_location_rounded,
      accent: AppColors.primary,
    ),
    'negation-trap': TrapPatternVisual(
      icon: Icons.do_not_disturb_on_rounded,
      accent: AppColors.wrong,
    ),
    'negative-framing': TrapPatternVisual(
      icon: Icons.quiz_rounded,
      accent: AppColors.info,
    ),
  };
}

class TrapPatternIconWell extends StatelessWidget {
  const TrapPatternIconWell({
    super.key,
    required this.trapType,
    this.size = 40,
    this.iconSize = 22,
  });

  final String trapType;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = TrapPatternVisual.of(trapType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visual.accent.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: visual.accent.withValues(alpha: isDark ? 0.55 : 0.35),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(visual.icon, size: iconSize, color: visual.accent),
    );
  }
}
