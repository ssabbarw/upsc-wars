import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Home hero for the newspaper quiz: read the paper, then answer its MCQs.
///
/// State is passed in so the Today hub owns the single ticking clock.
class DailyCaHomeCard extends StatelessWidget {
  const DailyCaHomeCard({
    super.key,
    required this.borderColor,
    required this.paperDate,
    required this.isTodaysPaper,
    required this.completed,
    required this.questionCount,
    required this.onStart,
    this.loading = false,
    this.emphasized = false,
  });

  final Color borderColor;

  /// News date of the open quiz, or null when nothing is open yet.
  final DateTime? paperDate;
  final bool isTodaysPaper;
  final bool completed;
  final int questionCount;
  final VoidCallback? onStart;
  final bool loading;

  /// Time-of-day hero — thicker border so it reads as the one to tap.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.infoTextDark : AppColors.infoText;

    final date = paperDate;
    final String headline;
    final String detail;
    if (date == null) {
      headline = 'No paper quiz open yet';
      detail = 'The next one opens at 6 AM';
    } else if (completed) {
      headline = isTodaysPaper
          ? "Today's paper — done"
          : '${DateFormat('d MMM').format(date)} paper — done';
      detail = 'Tap to revise the explanations';
    } else {
      headline = isTodaysPaper
          ? "Today's paper"
          : '${DateFormat('d MMM').format(date)} paper';
      detail = '$questionCount MCQs from the news you read';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onStart,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      completed
                          ? Icons.check_circle_outline_rounded
                          : Icons.newspaper_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT AFFAIRS',
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date == null
                        ? 'Opens 6 AM'
                        : completed
                        ? 'Revise'
                        : 'Start the quiz',
                    style: AppTextStyles.labelSm().copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/daily-ca'),
                    child: Text(
                      'All papers →',
                      style: AppTextStyles.labelSm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
