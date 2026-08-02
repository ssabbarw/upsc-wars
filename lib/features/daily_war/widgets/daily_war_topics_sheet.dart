import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../../../shared/widgets/top_snack_bar.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../theme/daily_war_theme.dart';

/// Full topic list for tonight's War, with a practice-test action per topic.
Future<void> showDailyWarTopicsSheet({
  required BuildContext context,
  required List<DailyWarTopicRef> topics,
}) {
  if (topics.isEmpty) return Future<void>.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DailyWarTopicsSheet(topics: topics),
  );
}

class _DailyWarTopicsSheet extends ConsumerWidget {
  const _DailyWarTopicsSheet({required this.topics});

  final List<DailyWarTopicRef> topics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final subjects = DailyWarCopy.subjectsLine(topics);

    // Transparent modal fills the screen; tap above the card to dismiss.
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text(
                            'Revise before 9 PM',
                            style: AppTextStyles.h3().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topics.length == 1
                                ? 'Tonight\'s war draws from this topic. Run the PYQs now so you walk in warm.'
                                : 'Tonight\'s war draws from these ${topics.length} topics. Run the PYQs now so you walk in warm.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          if (subjects.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              subjects.toUpperCase(),
                              style: AppTextStyles.caption().copyWith(
                                color: DwColors.crimson,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: topics.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = topics[i];
                          return _TopicPracticeRow(topic: t);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        'Revision here does not count towards your war rank.',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicPracticeRow extends ConsumerWidget {
  const _TopicPracticeRow({required this.topic});

  final DailyWarTopicRef topic;

  Future<void> _practice(BuildContext context, WidgetRef ref) async {
    final subject = DailyWarCopy.sessionSubjectSlug(topic.subjectSlug);
    final topics = await ref.read(topicTestTopicsProvider(subject).future);
    TopicInfo? match;
    for (final t in topics) {
      if (t.topic == topic.topic) {
        match = t;
        break;
      }
    }
    if (!context.mounted) return;
    if (match == null || match.questionCount <= 0) {
      showTopSnackBar(
        context,
        content: Text(
          match == null
              ? 'Topic not found in catalog.'
              : 'No questions available for this topic yet.',
        ),
      );
      return;
    }
    final subjDef = SubjectConstants.bySlug(subject);
    // Close topics sheet first so the config sheet sits cleanly.
    Navigator.of(context).pop();
    if (!context.mounted) return;
    await showTestConfigBottomSheet(
      context: context,
      args: TestConfigSheetArgs(
        subject: subject,
        topic: topic.topic,
        subjectDisplayName:
            subjDef?.displayName ?? DailyWarCopy.subjectDisplay(topic.subjectSlug),
        topicDisplayName: match.displayName,
        availableQuestionCount: match.questionCount,
        topicCountWhenSubjectOnly: 0,
        analyticsFeatureKey: 'daily_war_topic_practice',
        startButtonLabel: 'Start practice',
        onSessionCreated: (id) => context.push('/test/$id'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectLabel = DailyWarCopy.subjectDisplay(topic.subjectSlug);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.gray800.withValues(alpha: 0.45)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectLabel.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    color: DwColors.crimson,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.topic,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _practice(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: DwColors.crimson,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Practice',
              style: AppTextStyles.labelSm().copyWith(
                fontWeight: FontWeight.w700,
                color: DwColors.crimson,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
