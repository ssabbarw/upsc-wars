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

class PracticeTestListScreen extends ConsumerWidget {
  const PracticeTestListScreen({super.key, required this.subject, this.topic});

  final String subject;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = topic == null
        ? PracticeScope.subject(subject)
        : PracticeScope.topic(subject, topic!);
    final catalog = ref.watch(practiceCatalogProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final def = SubjectConstants.bySlug(subject);
    final title = topic == null
        ? (def?.displayName ?? subject)
        : (catalog.asData?.value.topicDisplayNames[topic] ?? topic!);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(practiceCatalogProvider),
            child: Text(context.l10n.commonRetry),
          ),
        ),
        data: (data) {
          final tests = data.testsFor(scope);
          final progress = data.progressFor(scope);
          final firstOpen = tests.indexWhere((t) => !t.isDone);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _Header(progress: progress, borderColor: borderColor),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (topic == null)
                    TextButton(
                      onPressed: () => context.push(
                        '/subject/${Uri.encodeComponent(subject)}/topics',
                      ),
                      child: Text(context.l10n.practiceBrowseTopics),
                    ),
                  TextButton(
                    onPressed: () => context.go(
                      '/stats?subject=${Uri.encodeQueryComponent(subject)}',
                    ),
                    child: Text(context.l10n.practiceSeeStats),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (tests.isEmpty)
                Text(
                  context.l10n.practiceNoTests,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              for (var i = 0; i < tests.length; i++) ...[
                _TestRow(
                  test: tests[i],
                  highlighted: i == firstOpen,
                  borderColor: borderColor,
                  onOpen: () => _open(
                    context,
                    ref,
                    subject: subject,
                    topic: topic,
                    title: title,
                    test: tests[i],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _open(
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
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.borderColor});

  final PracticeScopeProgress progress;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverage = progress.coveragePercent;
    final accuracy = progress.accuracyPercent;
    String pct(double? value) => value == null ? '—' : '${value.round()}%';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.practiceTestsProgress(
              progress.testsDone,
              progress.testsTotal,
            ),
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.l10n.statsCoverage(pct(coverage))}'
            ' · ${context.l10n.statsAccuracy(pct(accuracy))}',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({
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
