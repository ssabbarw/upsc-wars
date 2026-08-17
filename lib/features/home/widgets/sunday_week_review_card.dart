import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'today_loop_card.dart';

/// Sunday home card: re-attempt this week's wrong answers.
class SundayWeekReviewCard extends StatelessWidget {
  const SundayWeekReviewCard({
    super.key,
    required this.mistakeCount,
    required this.completed,
    required this.onStart,
    this.emphasized = false,
    this.loading = false,
    this.onStartDrillInstead,
    this.layout = TodayLoopLayout.hero,
  });

  final int mistakeCount;
  final bool completed;
  final bool emphasized;
  final bool loading;
  final VoidCallback? onStart;
  final VoidCallback? onStartDrillInstead;
  final TodayLoopLayout layout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    final hasMistakes = mistakeCount > 0;

    final String title;
    final String subtitle;
    final String cta;
    if (!hasMistakes) {
      title = 'Clean week';
      subtitle = layout == TodayLoopLayout.tile
          ? 'No misses logged'
          : 'Nothing to close from Mon–Sat. Take a light set if you want.';
      cta = 'Practice';
    } else if (completed) {
      title = 'Week review';
      subtitle = layout == TodayLoopLayout.tile
          ? 'Closed'
          : 'Those misses are closed. Open them if one still itches.';
      cta = layout == TodayLoopLayout.hero ? 'Open again' : 'Done';
    } else {
      title = layout == TodayLoopLayout.tile
          ? '$mistakeCount miss${mistakeCount == 1 ? '' : 'es'}'
          : 'Last week\'s misses';
      subtitle = layout == TodayLoopLayout.tile
          ? 'Mon–Sat'
          : 'The ones that got away. Close them before Monday.';
      cta = layout == TodayLoopLayout.hero ? 'Close the gaps' : 'Open';
    }

    return TodayLoopCard(
      layout: layout,
      eyebrow: 'SUNDAY',
      title: title,
      subtitle: subtitle,
      cta: cta,
      icon: hasMistakes ? Icons.replay_rounded : Icons.spa_outlined,
      accent: accent,
      background: isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
      onTap: hasMistakes ? onStart : onStartDrillInstead,
      done: completed,
      loading: loading,
      showNow: emphasized && layout == TodayLoopLayout.hero,
    );
  }
}
