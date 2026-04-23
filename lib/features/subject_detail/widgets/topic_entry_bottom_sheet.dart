import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../providers/topic_insights_provider.dart';
import 'danger_zone_summary_card.dart';

/// Subject-style bottom sheet for a topic: start a test + Danger zone for that topic.
Future<void> showTopicEntryBottomSheet({
  required BuildContext context,
  required String subject,
  required String topic,
  required String subjectDisplayName,
  required String topicDisplayName,
  required int availableQuestionCount,
  required void Function(String sessionId) onTestSessionCreated,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
  final parentContext = context;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (modalContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(modalContext).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(modalContext).height * 0.92,
            ),
            decoration: BoxDecoration(
              color: Theme.of(modalContext).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.sm,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: _TopicEntryBottomSheetBody(
                parentContext: parentContext,
                modalContext: modalContext,
                subject: subject,
                topic: topic,
                subjectDisplayName: subjectDisplayName,
                topicDisplayName: topicDisplayName,
                availableQuestionCount: availableQuestionCount,
                borderColor: borderColor,
                onTestSessionCreated: onTestSessionCreated,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TopicEntryBottomSheetBody extends ConsumerWidget {
  const _TopicEntryBottomSheetBody({
    required this.parentContext,
    required this.modalContext,
    required this.subject,
    required this.topic,
    required this.subjectDisplayName,
    required this.topicDisplayName,
    required this.availableQuestionCount,
    required this.borderColor,
    required this.onTestSessionCreated,
  });

  final BuildContext parentContext;
  final BuildContext modalContext;
  final String subject;
  final String topic;
  final String subjectDisplayName;
  final String topicDisplayName;
  final int availableQuestionCount;
  final Color borderColor;
  final void Function(String sessionId) onTestSessionCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final params = (subject: subject, topic: topic);
    final insightsAsync = ref.watch(topicInsightsProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          topicDisplayName,
          style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subjectDisplayName,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: availableQuestionCount <= 0
              ? null
              : () {
                  Navigator.of(modalContext).pop();
                  showTestConfigBottomSheet(
                    context: parentContext,
                    args: TestConfigSheetArgs(
                      subject: subject,
                      topic: topic,
                      subjectDisplayName: subjectDisplayName,
                      topicDisplayName: topicDisplayName,
                      availableQuestionCount: availableQuestionCount,
                      topicCountWhenSubjectOnly: 0,
                      onSessionCreated: onTestSessionCreated,
                    ),
                  );
                },
          child: Text(
            'Start a test',
            style: AppTextStyles.label(),
          ),
        ),
        if (availableQuestionCount <= 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No questions in this topic right now.',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'INSIGHTS',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        insightsAsync.when(
          loading: () => SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: scheme.primary),
            ),
          ),
          error: (e, _) => Text(
            'Could not load Danger zone.',
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
          data: (insights) => DangerZoneSummaryCard(
            dangerZoneContextLabel: topicDisplayName,
            subject: subject,
            topic: topic,
            insights: insights,
            borderColor: borderColor,
            onLearningSessionStarted: (sessionId) {
              Navigator.of(modalContext).pop();
              if (parentContext.mounted) {
                parentContext.push('/test/$sessionId');
              }
            },
          ),
        ),
      ],
    );
  }
}
