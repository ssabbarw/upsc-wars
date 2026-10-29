import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../domain/practice_scope.dart';
import '../providers/practice_catalog_provider.dart';

class PracticeTestTile extends StatelessWidget {
  const PracticeTestTile({
    super.key,
    required this.test,
    required this.highlighted,
    required this.borderColor,
    required this.onOpen,
  });

  final PracticeTest test;
  final bool highlighted;
  final Color borderColor;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = test.isDone;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.08)
                : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: highlighted ? AppColors.primary : borderColor,
              width: highlighted ? 1.2 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? AppColors.correct : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.practiceTestNumber(test.number),
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      context.l10n.practiceQuestionCount(test.questionCount),
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (done && test.lastCompleted?.score != null)
                Text(
                  '${test.lastCompleted!.score}',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
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

/// Opens a practice test: resume, review, or the config sheet.
Future<void> openPracticeTest(
  BuildContext context,
  WidgetRef ref, {
  required String subject,
  required String? topic,
  required String title,
  required PracticeTest test,
}) async {
  final resume = test.inProgressSessionId;
  if (resume != null && !test.isDone) {
    await context.push('/test/$resume');
    ref.invalidate(practiceCatalogProvider);
    return;
  }
  if (test.isDone && test.lastCompleted != null) {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _AttemptedTestSheet(test: test),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'review') {
      await context.push('/history/${test.lastCompleted!.sessionId}');
      return;
    }
  }
  unawaited(
    Analytics.track(ref, PracticeTestStartedEvent(testId: test.testId)),
  );
  if (!context.mounted) return;
  await showTestConfigBottomSheet(
    context: context,
    args: TestConfigSheetArgs(
      subject: subject,
      topic: topic,
      subjectDisplayName:
          SubjectConstants.bySlug(subject)?.displayName ?? subject,
      topicDisplayName: topic == null ? null : title,
      availableQuestionCount: test.questionCount,
      topicCountWhenSubjectOnly: 0,
      lockedQuestionCount: test.questionCount,
      specificQuestionUuids: test.uuids,
      practiceTestId: test.testId,
      fixedQuestionSetLabel: context.l10n.practiceTestNumber(test.number),
      analyticsFeatureKey: 'practice_test',
      onSessionCreated: (id) {
        ref.invalidate(practiceCatalogProvider);
        context.push('/test/$id');
      },
    ),
  );
}

class _AttemptedTestSheet extends StatelessWidget {
  const _AttemptedTestSheet({required this.test});

  final PracticeTest test;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final completion = test.lastCompleted;
    final score = completion?.score;
    final total = completion?.questionCount ?? test.questionCount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.practiceTestNumber(test.number),
                        style: AppTextStyles.h2().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.practiceQuestionCount(test.questionCount),
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (score != null)
                  _LastScoreBadge(
                    score: score,
                    total: total > 0 ? total : null,
                    label: context.l10n.practiceLastScore,
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _AttemptAction(
              icon: Icons.fact_check_outlined,
              color: AppColors.info,
              title: context.l10n.practiceReviewLast,
              subtitle: context.l10n.practiceReviewLastBody,
              borderColor: borderColor,
              onTap: () => Navigator.pop(context, 'review'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AttemptAction(
              icon: Icons.replay_rounded,
              color: AppColors.primary,
              title: context.l10n.practiceReattempt,
              subtitle: context.l10n.practiceReattemptBody,
              borderColor: borderColor,
              onTap: () => Navigator.pop(context, 'retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastScoreBadge extends StatelessWidget {
  const _LastScoreBadge({
    required this.score,
    required this.total,
    required this.label,
    required this.isDark,
  });

  final int score;
  final int? total;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final valueColor = isDark
        ? AppColors.correctTextDark
        : AppColors.correctText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.correctBgDark : AppColors.correctBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$score',
                  style: AppTextStyles.h2().copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (total != null)
                  TextSpan(
                    text: ' / $total',
                    style: AppTextStyles.bodySm().copyWith(color: valueColor),
                  ),
              ],
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _AttemptAction extends StatelessWidget {
  const _AttemptAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.12);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
