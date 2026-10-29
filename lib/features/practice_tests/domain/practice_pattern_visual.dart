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
  return PracticePatternVisual(
    icon: _iconFor(pattern),
    accent: _accentFor(pattern, isDark: isDark, index: index),
  );
}

IconData _iconFor(SubjectMcqPatternStat pattern) {
  switch (pattern.pattern) {
    case UpscMcqPattern.howMany:
      return Icons.filter_3_rounded;
    case UpscMcqPattern.statementCombination:
      return Icons.fact_check_rounded;
    case UpscMcqPattern.assertionReason:
      return Icons.account_tree_rounded;
    case UpscMcqPattern.matchFollowing:
      return Icons.mediation_rounded;
    case UpscMcqPattern.direct:
      return Icons.bolt_rounded;
    case UpscMcqPattern.singleStatement:
      return Icons.format_quote_rounded;
    case UpscMcqPattern.other:
      return _iconForOther(pattern.otherSlug);
  }
}

IconData _iconForOther(String? slug) {
  final key = slug ?? '';
  if (key.contains('fill-in') || key.contains('blank')) {
    return Icons.text_fields_rounded;
  }
  if (key.contains('chronolog') || key.contains('timeline')) {
    return Icons.timeline_rounded;
  }
  if (key.contains('quantitative') || key.contains('pairing')) {
    return Icons.calculate_rounded;
  }
  if (key.contains('identify-the-pair') || key.contains('pair')) {
    return Icons.looks_two_rounded;
  }
  if (key.contains('odd-one')) {
    return Icons.difference_rounded;
  }
  if (key.contains('incorrect')) {
    return Icons.playlist_remove_rounded;
  }
  if (key.contains('application') || key.contains('scenario')) {
    return Icons.extension_rounded;
  }
  if (key.contains('relationship') || key.contains('two-statement')) {
    return Icons.merge_type_rounded;
  }
  if (key.contains('map')) {
    return Icons.map_rounded;
  }
  if (key.contains('negative')) {
    return Icons.block_rounded;
  }
  if (key.contains('conceptual')) {
    return Icons.lightbulb_rounded;
  }
  return Icons.category_rounded;
}

Color _accentFor(
  SubjectMcqPatternStat pattern, {
  required bool isDark,
  required int index,
}) {
  final named = switch (pattern.pattern) {
    UpscMcqPattern.howMany => isDark ? AppColors.infoTextDark : AppColors.info,
    UpscMcqPattern.statementCombination =>
      isDark ? AppColors.purpleTextDark : AppColors.purple,
    UpscMcqPattern.assertionReason =>
      isDark ? AppColors.warningTextDark : AppColors.warning,
    UpscMcqPattern.matchFollowing =>
      isDark ? AppColors.wrongTextDark : AppColors.wrong,
    UpscMcqPattern.direct =>
      isDark ? AppColors.warningTextDark : AppColors.warning,
    UpscMcqPattern.singleStatement =>
      isDark ? AppColors.infoTextDark : AppColors.info,
    UpscMcqPattern.other => null,
  };
  if (named != null) return named;
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
  final slug = pattern.otherSlug ?? '';
  if (slug.isEmpty) return palette[index % palette.length];
  return palette[slug.hashCode.abs() % palette.length];
}
