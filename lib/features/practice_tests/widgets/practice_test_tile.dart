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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(ctx.l10n.practiceReviewLast),
              onTap: () => Navigator.pop(ctx, 'review'),
            ),
            ListTile(
              title: Text(ctx.l10n.practiceReattempt),
              onTap: () => Navigator.pop(ctx, 'retry'),
            ),
          ],
        ),
      ),
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
