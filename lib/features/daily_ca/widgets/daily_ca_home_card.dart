import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/widgets/today_loop_card.dart';

/// Newspaper quiz on home — hero, tile, or banner depending on the Today hub.
class DailyCaHomeCard extends StatelessWidget {
  const DailyCaHomeCard({
    super.key,
    required this.paperDate,
    required this.isTodaysPaper,
    required this.completed,
    required this.questionCount,
    required this.onStart,
    this.loading = false,
    this.emphasized = false,
    this.layout = TodayLoopLayout.hero,
  });

  final DateTime? paperDate;
  final bool isTodaysPaper;
  final bool completed;
  final int questionCount;
  final VoidCallback? onStart;
  final bool loading;

  /// Time-of-day hero — kept for call sites; [layout] owns the paint.
  final bool emphasized;
  final TodayLoopLayout layout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final background = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final date = paperDate;

    final String title;
    final String subtitle;
    final String cta;
    if (date == null) {
      title = 'Paper quiz';
      subtitle = 'Opens at 6 AM — yesterday\'s news, today\'s questions.';
      cta = 'Soon';
    } else if (completed) {
      title = isTodaysPaper
          ? "Today's paper"
          : '${DateFormat('d MMM').format(date)} paper';
      subtitle = layout == TodayLoopLayout.tile
          ? 'Locked in'
          : 'Locked in. Open the explanations if a line still nags.';
      cta = layout == TodayLoopLayout.hero ? 'Open answers' : 'Answers';
    } else {
      title = isTodaysPaper
          ? "Today's paper"
          : '${DateFormat('d MMM').format(date)} paper';
            subtitle = layout == TodayLoopLayout.tile
          ? 'From this morning\'s news'
          : 'You already read it. $questionCount questions make it stay.';
      cta = layout == TodayLoopLayout.hero ? 'Lock it in' : 'Open';
    }

    return TodayLoopCard(
      layout: layout,
      eyebrow: 'CURRENT',
      title: title,
      subtitle: subtitle,
      cta: cta,
      icon: Icons.newspaper_rounded,
      accent: accent,
      background: background,
      onTap: onStart,
      done: completed,
      loading: loading,
      showNow: emphasized && layout == TodayLoopLayout.hero,
      footer: layout == TodayLoopLayout.hero
          ? GestureDetector(
              onTap: () => context.push('/daily-ca'),
              child: Text(
                'All papers',
                style: AppTextStyles.labelSm().copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}
