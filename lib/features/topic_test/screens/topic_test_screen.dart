import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../providers/topic_test_ui_providers.dart';

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class TopicTestScreen extends HookConsumerWidget {
  const TopicTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final selectedSlug = ref.watch(topicTestSelectedSubjectSlugProvider);
    final searchController = useTextEditingController();
    final topicsAsync = ref.watch(topicTestDisplayedTopicsProvider);
    final revisionCountsAsync = ref.watch(topicRevisionQueueCountsByTopicProvider);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: scheme.onSurface,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Topic test',
                      style: AppTextStyles.h2()
                          .copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ScrollConfiguration(
                behavior: const _NoScrollbarBehavior(),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: SubjectConstants.ordered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final def = SubjectConstants.ordered[i];
                    final selected = def.slug == selectedSlug;
                    return GestureDetector(
                      onTap: () {
                        searchController.clear();
                        ref
                            .read(topicTestSearchQueryProvider.notifier)
                            .setQuery('');
                        ref
                            .read(topicTestSelectedSubjectSlugProvider.notifier)
                            .setSlug(def.slug);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : scheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : borderColor,
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          def.displayName,
                          style: AppTextStyles.labelSm().copyWith(
                            color: selected
                                ? AppColors.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: searchController,
                onChanged: (v) => ref
                    .read(topicTestSearchQueryProvider.notifier)
                    .setQuery(v),
                style: AppTextStyles.body()
                    .copyWith(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search topics...',
                  hintStyle: AppTextStyles.body().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No topics match your search.',
                            style: AppTextStyles.body()
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const ContactUsTextButton(),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: topics.length + 1,
                    separatorBuilder: (context, index) {
                      if (index == topics.length - 1) {
                        return const SizedBox(height: AppSpacing.xl);
                      }
                      return const SizedBox(height: AppSpacing.cardListGap);
                    },
                    itemBuilder: (context, i) {
                      if (i == topics.length) {
                        return const Center(child: ContactUsTextButton());
                      }
                      final t = topics[i];
                      final subj = SubjectConstants.bySlug(t.subject);
                      final revisionQueueCount = revisionCountsAsync.maybeWhen(
                        data: (counts) => counts[t.topic] ?? 0,
                        orElse: () => 0,
                      );
                      final isWeak = t.attemptCount > 0 && (t.accuracyPercent ?? 0) < 50;
                      return _TopicRow(
                        topic: t,
                        borderColor: borderColor,
                        revisionQueueCount: revisionQueueCount,
                        isWeak: isWeak,
                        onTap: () => showTestConfigBottomSheet(
                          context: context,
                          args: TestConfigSheetArgs(
                            subject: t.subject,
                            topic: t.topic,
                            subjectDisplayName:
                                subj?.displayName ?? t.subject,
                            topicDisplayName: t.displayName,
                            availableQuestionCount: t.questionCount,
                            topicCountWhenSubjectOnly: 0,
                            onSessionCreated: (id) =>
                                context.push('/test/$id'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: 9,
                  separatorBuilder: (context, index) {
                    if (index == 7) {
                      return const SizedBox(height: AppSpacing.xl);
                    }
                    return const SizedBox(height: AppSpacing.sm);
                  },
                  itemBuilder: (context, index) {
                    if (index == 8) {
                      return const Center(child: ContactUsTextButton());
                    }
                    return Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    );
                  },
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load topics.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body()
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () {
                            ref.invalidate(topicTestDisplayedTopicsProvider);
                            ref.invalidate(topicRevisionQueueCountsByTopicProvider);
                          },
                          child: Text('Retry', style: AppTextStyles.label()),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const ContactUsTextButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends HookConsumerWidget {
  const _TopicRow({
    required this.topic,
    required this.borderColor,
    required this.revisionQueueCount,
    required this.isWeak,
    required this.onTap,
  });

  final TopicInfo topic;
  final Color borderColor;
  final int revisionQueueCount;
  final bool isWeak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
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
                color: isWeak ? AppColors.wrong : AppColors.transparent,
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
                              style: AppTextStyles.label()
                                  .copyWith(color: scheme.onSurface),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${formatIntCount(topic.questionCount)} questions',
                              style: AppTextStyles.bodySm()
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AccuracyPercentageText(
                              attemptCount: topic.attemptCount,
                              accuracyPercent: topic.accuracyPercent,
                              tier: topic.accuracyTier,
                            ),
                            if (revisionQueueCount > 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '$revisionQueueCount in revision queue',
                                style: AppTextStyles.caption()
                                    .copyWith(color: scheme.onSurfaceVariant),
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
            ],
          ),
        ),
      ),
    );
  }
}
