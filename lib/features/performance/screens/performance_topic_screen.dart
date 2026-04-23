import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../../../shared/widgets/top_snack_bar.dart';
import '../providers/performance_providers.dart';
import '../widgets/simple_sparkline.dart';

class PerformanceTopicScreen extends ConsumerWidget {
  const PerformanceTopicScreen({
    super.key,
    required this.subject,
    required this.topic,
  });

  final String subject;
  final String topic;

  Future<void> _startTopicTest(BuildContext context, WidgetRef ref) async {
    final topics = await ref.read(topicTestTopicsProvider(subject).future);
    TopicInfo? match;
    for (final t in topics) {
      if (t.topic == topic) {
        match = t;
        break;
      }
    }
    if (!context.mounted) return;
    if (match == null) {
      showTopSnackBar(
        context,
        content: const Text('Topic not found in catalog.'),
      );
      return;
    }
    if (match.questionCount <= 0) {
      showTopSnackBar(
        context,
        content: const Text('No questions available for this topic yet.'),
      );
      return;
    }
    final subjDef = SubjectConstants.bySlug(subject);
    await showTestConfigBottomSheet(
      context: context,
      args: TestConfigSheetArgs(
        subject: subject,
        topic: topic,
        subjectDisplayName: subjDef?.displayName ?? subject,
        topicDisplayName: match.displayName,
        availableQuestionCount: match.questionCount,
        topicCountWhenSubjectOnly: 0,
        analyticsFeatureKey: 'performance_mentor_topic_test',
        startButtonLabel: 'Start topic test',
        onSessionCreated: (id) {
          context.push(
            '/results/$id?mentor=1&perfSubject=${Uri.encodeComponent(subject)}'
            '&perfTopic=${Uri.encodeComponent(topic)}',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = performanceTopicKey(subject, topic);
    final async = ref.watch(performanceTopicMentorProvider(key));
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load topic', style: AppTextStyles.body()),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(performanceTopicMentorProvider(key)),
                    child: Text('Retry', style: AppTextStyles.label()),
                  ),
                ],
              ),
            ),
          ),
          data: (m) {
            final z = m.zones;
            final trend = m.correctWrongTrend14d.map((p) => p.value).toList();
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(performanceTopicMentorProvider(key));
                await ref.read(performanceTopicMentorProvider(key).future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          topic,
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subject,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    m.statusHeadline,
                    style: AppTextStyles.h2().copyWith(
                      color: scheme.onSurface,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Because:',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  ...m.riskReasonLines.map(
                    (line) => Text('• $line', style: AppTextStyles.bodySm()),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Why this is happening',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(m.whyCopy, style: AppTextStyles.body()),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Confidence zones',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ZoneTile(
                    title: 'Dangerous zone · sure + incorrect',
                    count: z.sureWrong,
                    hint: 'Highest priority — slow down and verify traps.',
                    borderColor: borderColor,
                    accent: AppColors.wrong,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ZoneTile(
                    title: 'Risky guessing · educated guess + incorrect',
                    count: z.educatedWrong,
                    hint:
                        'Avoid aggressive attempts until concepts are tighter.',
                    borderColor: borderColor,
                    accent: scheme.tertiary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ZoneTile(
                    title: 'Reliable strength · sure + correct',
                    count: z.sureCorrect,
                    hint: 'Strong conceptual hold.',
                    borderColor: borderColor,
                    accent: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ZoneTile(
                    title: 'Smart guessing strength · educated guess + correct',
                    count: z.educatedCorrect,
                    hint: 'Strong elimination — leverage in exam when needed.',
                    borderColor: borderColor,
                    accent: AppColors.primaryDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ZoneTile(
                    title: 'Pure guess',
                    count: z.pureGuessCorrect + z.pureGuessWrong,
                    hint:
                        'Correct: ${z.pureGuessCorrect} · wrong: ${z.pureGuessWrong}',
                    borderColor: borderColor,
                    accent: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Recommended action',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(m.recommendedAction, style: AppTextStyles.body()),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => _startTopicTest(context, ref),
                    child: Text(
                      'Attempt 10-question topic test',
                      style: AppTextStyles.label(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.push('/revision-queue'),
                    child: Text(
                      'Open revision queue',
                      style: AppTextStyles.label(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Accuracy trend (14 days)',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: borderColor, width: 0.5),
                    ),
                    child: SimpleSparkline(points: trend),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Higher line = more correct per day. Next step: test, then compare this chart again.',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.title,
    required this.count,
    required this.hint,
    required this.borderColor,
    required this.accent,
  });

  final String title;
  final int count;
  final String hint;
  final Color borderColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label()),
                const SizedBox(height: AppSpacing.xs),
                Text('$count attempts', style: AppTextStyles.caption()),
                Text(hint, style: AppTextStyles.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
