import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../subject_detail/domain/subject_mcq_pattern.dart';

class PracticePatternVisual {
  const PracticePatternVisual({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

PracticePatternVisual practicePatternVisual(
  SubjectMcqPatternStat pattern, {
  required bool isDark,
  int index = 0,
}) {
  final palette = isDark
      ? const [
          AppColors.wrongTextDark,
          AppColors.warningTextDark,
          AppColors.purpleTextDark,
          AppColors.infoTextDark,
        ]
      : const [
          AppColors.wrong,
          AppColors.warning,
          AppColors.purple,
          AppColors.info,
        ];
  return PracticePatternVisual(
    icon: _iconFor(pattern.pattern),
    accent: palette[index % palette.length],
  );
}

IconData _iconFor(UpscMcqPattern pattern) {
  switch (pattern) {
    case UpscMcqPattern.howMany:
      return Icons.format_list_numbered_rounded;
    case UpscMcqPattern.statementCombination:
      return Icons.list_alt_rounded;
    case UpscMcqPattern.assertionReason:
      return Icons.swap_horiz_rounded;
    case UpscMcqPattern.matchFollowing:
      return Icons.compare_arrows_rounded;
    case UpscMcqPattern.direct:
      return Icons.bolt_rounded;
    case UpscMcqPattern.singleStatement:
      return Icons.short_text_rounded;
    case UpscMcqPattern.other:
      return Icons.category_rounded;
  }
}
