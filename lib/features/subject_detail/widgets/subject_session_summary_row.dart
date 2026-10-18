import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/entities/session_summary.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';

String relativeSessionListDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) return appL10n.commonToday;
  if (diff.inDays == 1) return appL10n.commonYesterday;
  if (diff.inDays < 7) return appL10n.commonDaysAgo(diff.inDays);
  return DateFormat('d MMM y').format(dt);
}

/// One completed (or listed) session row: opens session review on tap.
class SubjectSessionSummaryRow extends StatelessWidget {
  const SubjectSessionSummaryRow({
    super.key,
    required this.session,
    required this.borderColor,
  });

  final SessionSummary session;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLearning = session.mode == 'learning';
    final modeLabel = isLearning
        ? context.l10n.subjModeLearning
        : context.l10n.subjModeExam;
    final modeColor = isLearning ? AppColors.primary : AppColors.info;
    final modeBg = isLearning ? AppColors.correctBg : AppColors.infoBg;

    final accuracy = session.accuracy;
    final correct = session.correct;
    final total = session.questionCount;
    final scoreText = accuracy != null && correct != null
        ? context.l10n.subjCorrectOfTotal(
            correct,
            total,
            accuracy.toStringAsFixed(0),
          )
        : context.l10n.subjQuestionsPlain(total);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => context.push('/history/${session.sessionId}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: modeBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            modeLabel,
                            style: AppTextStyles.caption().copyWith(
                              color: modeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          relativeSessionListDate(session.createdAt),
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      scoreText,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (session.topic != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        session.topic!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
