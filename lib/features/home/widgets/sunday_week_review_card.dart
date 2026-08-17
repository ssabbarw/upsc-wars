import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

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
  });

  final int mistakeCount;
  final bool completed;
  final bool emphasized;
  final bool loading;
  final VoidCallback? onStart;
  final VoidCallback? onStartDrillInstead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final accent = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    final hasMistakes = mistakeCount > 0;

    final String headline;
    final String detail;
    if (!hasMistakes) {
      headline = 'Clean week';
      detail = 'No mistakes logged Mon–Sat';
    } else if (completed) {
      headline = 'Week review — done';
      detail = 'Tap to revise again';
    } else {
      headline = 'Last week\'s mistakes';
      detail = '$mistakeCount MCQ${mistakeCount == 1 ? '' : 's'} you got wrong';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading
            ? null
            : hasMistakes
            ? onStart
            : onStartDrillInstead,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: emphasized
                  ? accent
                  : completed
                  ? accent.withValues(alpha: 0.35)
                  : borderColor,
              width: emphasized ? 2 : (completed ? 1.5 : 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle_outline_rounded
                      : hasMistakes
                      ? Icons.replay_rounded
                      : Icons.spa_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEK REVIEW',
                      style: AppTextStyles.caption().copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd().copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      loading
                          ? 'Loading…'
                          : hasMistakes
                          ? (completed ? 'Revise again' : 'Start review')
                          : 'Start a drill instead',
                      style: AppTextStyles.labelSm().copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
