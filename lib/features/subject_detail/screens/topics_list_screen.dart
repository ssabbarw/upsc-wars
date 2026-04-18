import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/extensions/count_formatting.dart';
import '../../../shared/widgets/accuracy_percentage_text.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../providers/subject_detail_providers.dart';

class TopicsListScreen extends ConsumerWidget {
  const TopicsListScreen({super.key, required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final subjectDef = SubjectConstants.bySlug(subject);
    final displayName = subjectDef?.displayName ?? subject;

    final topicsAsync = ref.watch(subjectTopicsProvider(subject));

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: scheme.onSurface,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayName Topics',
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        topicsAsync.when(
                          data: (topics) => Text(
                            '${topics.length} topics',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Topics list
            Expanded(
              child: topicsAsync.when(
                loading: () => _LoadingSkeleton(),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(subjectTopicsProvider(subject)),
                ),
                data: (topics) {
                  if (topics.isEmpty) {
                    return _EmptyState();
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: topics.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardListGap),
                    itemBuilder: (context, i) => _TopicCard(
                      topic: topics[i],
                      subject: subject,
                      displayName: displayName,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topic Card ──────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.subject,
    required this.displayName,
    required this.borderColor,
    required this.isDark,
  });

  final TopicInfo topic;
  final String subject;
  final String displayName;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWeak = topic.attemptCount > 0 && (topic.accuracyPercent ?? 100) < 50;
    final notStarted = topic.attemptCount == 0;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => showTestConfigBottomSheet(
          context: context,
          args: TestConfigSheetArgs(
            subject: subject,
            topic: topic.topic,
            subjectDisplayName: displayName,
            topicDisplayName: topic.displayName,
            availableQuestionCount: topic.questionCount,
            topicCountWhenSubjectOnly: 0,
            onSessionCreated: (id) => context.push('/test/$id'),
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: double.infinity,
                color: isWeak
                    ? AppColors.wrong
                    : notStarted
                        ? AppColors.transparent
                        : AppColors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.displayName,
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${formatIntCount(topic.questionCount)} questions',
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (notStarted)
                              Text(
                                'Not started',
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              )
                            else
                              AccuracyPercentageText(
                                attemptCount: topic.attemptCount,
                                accuracyPercent: topic.accuracyPercent,
                                tier: topic.accuracyTier,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(notStarted: notStarted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.notStarted});
  final bool notStarted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          notStarted ? 'Start' : 'Practice',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
      ],
    );
  }
}

// ── Loading / Error / Empty states ─────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: 8,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.cardListGap),
      itemBuilder: (_, _) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load topics.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('Retry', style: AppTextStyles.label()),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.topic_outlined, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Topics coming soon.',
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
