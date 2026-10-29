import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../domain/practice_pattern_visual.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_subject_insights.dart';
import '../domain/practice_topic_visual.dart';
import '../providers/practice_catalog_provider.dart';
import '../providers/practice_subject_insights_provider.dart';
import '../widgets/practice_snapshot_card.dart';
import '../widgets/practice_test_tile.dart';

const _previewTrapCount = 3;

/// Overall performance plus confident-mistake traps and topics.
class PracticeSubjectInsightsScreen extends ConsumerWidget {
  const PracticeSubjectInsightsScreen({super.key, required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final displayName =
        SubjectConstants.bySlug(subject)?.displayName ?? subject;
    final catalog = ref.watch(practiceCatalogProvider);
    final insights = ref.watch(practiceSubjectInsightsProvider(subject));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(context.l10n.practiceInsightsTitle(displayName)),
          backgroundColor: scheme.surfaceContainerLowest,
          surfaceTintColor: AppColors.transparent,
        ),
        body: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(practiceCatalogProvider),
              child: Text(context.l10n.commonRetry),
            ),
          ),
          data: (data) {
            final progress =
                data.subjectProgress[subject] ?? PracticeScopeProgress.empty;
            return insights.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(practiceSubjectInsightsProvider(subject)),
                  child: Text(context.l10n.commonRetry),
                ),
              ),
              data: (value) {
                void revise(String topicKey) => _reviseTopic(
                  context,
                  ref,
                  catalog: data,
                  subject: subject,
                  topicKey: topicKey,
                );
                return NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                context.l10n.practiceOverallPerformance,
                                style: AppTextStyles.label().copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            PracticeSnapshotCard(
                              progress: progress,
                              insights: AsyncValue.data(value),
                            ),
                            if (value.surePatterns.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xl),
                              _TrapsPreview(
                                subject: subject,
                                patterns: value.surePatterns,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TopicTabBarDelegate(
                        background: scheme.surfaceContainerLowest,
                        tabBar: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 2.5,
                          labelColor: scheme.onSurface,
                          unselectedLabelColor: scheme.onSurfaceVariant,
                          labelStyle: AppTextStyles.label().copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: AppTextStyles.label(),
                          dividerColor: scheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                          tabs: [
                            Tab(text: context.l10n.practiceTopicsReviseTab),
                            Tab(text: context.l10n.practiceLensTabSure),
                            Tab(text: context.l10n.practiceLensTabGuess),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      _TopicList(
                        topics: value.reviseTopics,
                        empty: context.l10n.practiceReviseTopicsEmpty,
                        onRevise: revise,
                      ),
                      _TopicList(
                        topics: value.sureTopics,
                        empty: context.l10n.practiceSureTopicsEmpty,
                        onRevise: revise,
                      ),
                      _TopicList(
                        topics: value.guessTopics,
                        empty: context.l10n.practiceGuessTopicsEmpty,
                        onRevise: revise,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopicTabBarDelegate extends SliverPersistentHeaderDelegate {
  _TopicTabBarDelegate({required this.tabBar, required this.background});

  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TopicTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        background != oldDelegate.background;
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList({
    required this.topics,
    required this.empty,
    required this.onRevise,
  });

  final List<LensTopic> topics;
  final String empty;
  final ValueChanged<String> onRevise;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [_EmptyNote(empty)],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _TopicRow(topic: topic, onRevise: () => onRevise(topic.topicKey));
      },
    );
  }
}

Future<void> _reviseTopic(
  BuildContext context,
  WidgetRef ref, {
  required PracticeCatalog catalog,
  required String subject,
  required String topicKey,
}) async {
  final tests =
      catalog.topicTests[subject]?[topicKey] ?? const <PracticeTest>[];
  if (tests.isEmpty) {
    await context.push(
      '/subject/${Uri.encodeComponent(subject)}/topic/${Uri.encodeComponent(topicKey)}/tests',
    );
    return;
  }
  final nextIndex = tests.indexWhere((t) => !t.isDone);
  final test = tests[nextIndex < 0 ? 0 : nextIndex];
  final title = catalog.topicDisplayNames[topicKey] ?? topicKey;
  await openPracticeTest(
    context,
    ref,
    subject: subject,
    topic: topicKey,
    title: title,
    test: test,
  );
}

class _TrapsPreview extends StatelessWidget {
  const _TrapsPreview({required this.subject, required this.patterns});

  final String subject;
  final List<SubjectMcqPatternStat> patterns;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = patterns.take(_previewTrapCount).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warningBgDark.withValues(alpha: 0.45)
            : AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                size: 22,
                color: isDark ? AppColors.warningTextDark : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.practiceTrapsTitleSure(patterns.length),
                  style: AppTextStyles.h3().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.practiceTrapsLeadSure,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < preview.length; i++) ...[
            _TrapPreviewRow(index: i, pattern: preview[i]),
            if (i < preview.length - 1) const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push(
                '/subject/${Uri.encodeComponent(subject)}/insights/traps',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.practiceTrapsReview),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrapPreviewRow extends StatelessWidget {
  const _TrapPreviewRow({required this.index, required this.pattern});

  final int index;
  final SubjectMcqPatternStat pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = practicePatternVisual(pattern, isDark: isDark, index: index);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: visual.accent.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Icon(visual.icon, size: 20, color: visual.accent),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pattern.labelFor(context.l10n),
                      style: AppTextStyles.labelSm().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.practiceTrapsErrors(pattern.wrong),
                    style: AppTextStyles.caption().copyWith(
                      color: visual.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                pattern.explainFor(context.l10n),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.onRevise});

  final LensTopic topic;
  final VoidCallback onRevise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = practiceTopicVisual(topic.topicKey, isDark: isDark);
    final wrongColor = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.accent.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, size: 22, color: visual.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.displayName,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: onRevise,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: wrongColor,
                        side: BorderSide(
                          color: AppColors.wrong.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          4,
                          AppSpacing.xs,
                          4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.commonRevise,
                            style: AppTextStyles.caption().copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: wrongColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.practiceLensSplit(
                          topic.correct,
                          topic.wrong,
                        ),
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: (topic.wrongRate / 100).clamp(0, 1),
                          minHeight: 4,
                          backgroundColor: isDark
                              ? AppColors.gray800
                              : AppColors.gray50,
                          color: wrongColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.practiceTopicWrongPct(
                        topic.wrongRate.round(),
                      ),
                      style: AppTextStyles.caption().copyWith(
                        color: wrongColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySm().copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
