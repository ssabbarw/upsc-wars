import 'package:flutter/material.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../../l10n/l10n.dart';

/// Bottom sheet for today's paper: start, revise, or review answers.
Future<void> showDailyCaActionSheet({
  required BuildContext context,
  required bool paperLive,
  required bool paperCompleted,
  VoidCallback? onStart,
  VoidCallback? onRevise,
  VoidCallback? onReviewAnswers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.only(bottom: sheetBottomPadding(ctx)),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "Today's paper",
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    !paperLive
                        ? ctx.l10n.dcaQuizNotOpen
                        : paperCompleted
                        ? ctx.l10n.dcaAlreadySubmitted
                        : ctx.l10n.dcaSameQuestions,
                    style: AppTextStyles.bodySm().copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (paperLive && !paperCompleted && onStart != null)
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onStart();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(ctx.l10n.testStartTest),
                    ),
                  if (paperLive && paperCompleted) ...[
                    if (onReviewAnswers != null)
                      FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onReviewAnswers();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: Text(ctx.l10n.dcaReviewAnswers),
                      ),
                    if (onRevise != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onRevise();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: Text(ctx.l10n.dcaReviseLearning),
                      ),
                    ],
                  ],
                  if (!paperLive)
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(ctx.l10n.commonGotIt),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
