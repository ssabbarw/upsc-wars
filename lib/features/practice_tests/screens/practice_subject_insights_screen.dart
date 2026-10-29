import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/presentation/topic_label.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../../core/providers/trap_descriptions_provider.dart';
import '../../weak_areas/widgets/trap_info_button.dart';
import '../../weak_areas/widgets/trap_pattern_visual.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_subject_insights.dart';
import '../domain/practice_topic_visual.dart';
import '../open_insight_practice.dart';
import '../providers/practice_catalog_provider.dart';
import '../providers/practice_subject_insights_provider.dart';
import '../widgets/practice_snapshot_card.dart';

const _previewTrapCount = 3;

/// Overall performance plus confident-mistake traps and topics.
class PracticeSubjectInsightsScreen extends ConsumerWidget {
  const PracticeSubjectInsightsScreen({
    super.key,
    required this.subject,
    this.topic,
  });

  final String subject;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final catalog = ref.watch(practiceCatalogProvider);
    final displayName = topic == null
        ? (SubjectConstants.bySlug(subject)?.displayName ?? subject)
        : (catalog.asData?.value.topicDisplayNames[topic] ?? topic!);
    final insights = topic == null
        ? ref.watch(practiceSubjectInsightsProvider(subject))
        : ref.watch(
            practiceTopicInsightsProvider((subject: subject, topic: topic!)),
          );

    return Scaffold(
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
          final progress = topic == null
              ? (data.subjectProgress[subject] ?? PracticeScopeProgress.empty)
              : (data.topicProgress[subject]?[topic] ??
                    PracticeScopeProgress.empty);
          return insights.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () {
                  if (topic == null) {
                    ref.invalidate(practiceSubjectInsightsProvider(subject));
                  } else {
                    ref.invalidate(
                      practiceTopicInsightsProvider((
                        subject: subject,
                        topic: topic!,
                      )),
                    );
                  }
                },
                child: Text(context.l10n.commonRetry),
              ),
            ),
            data: (value) {
              final lead = _InsightsLead(
                subject: subject,
                topic: topic,
                displayName: displayName,
                progress: progress,
                insights: value,
              );
              if (topic != null) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [lead],
                );
              }
              return DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: lead,
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
                        subject: subject,
                        sureLens: true,
                        topics: value.sureTopics,
                        lead: context.l10n.practiceSureTopicsLead(displayName),
                        empty: context.l10n.practiceSureTopicsEmpty,
                      ),
                      _TopicList(
                        subject: subject,
                        sureLens: false,
                        topics: value.guessTopics,
                        lead: context.l10n.practiceGuessTopicsLead(displayName),
                        empty: context.l10n.practiceGuessTopicsEmpty,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InsightsLead extends StatelessWidget {
  const _InsightsLead({
    required this.subject,
    this.topic,
    required this.displayName,
    required this.progress,
    required this.insights,
  });

  final String subject;
  final String? topic;
  final String displayName;
  final PracticeScopeProgress progress;
  final PracticeSubjectInsights insights;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final guessVerdict = topic == null
        ? null
        : guessNetVerdict(
            correct: insights.educatedGuessCorrect,
            wrong: insights.educatedGuessWrong,
          );
    return Column(
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
          insights: AsyncValue.data(insights),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.practiceStatsSourcesNote(displayName),
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (guessVerdict != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _TopicGuessVerdictCard(
            subject: subject,
            topic: topic!,
            title: displayName,
            verdict: guessVerdict,
          ),
        ],
        if (insights.sureTraps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _TrapsPreview(
            subject: subject,
            topic: topic,
            traps: insights.sureTraps,
          ),
        ],
      ],
    );
  }
}

class _TopicGuessVerdictCard extends StatelessWidget {
  const _TopicGuessVerdictCard({
    required this.subject,
    required this.topic,
    required this.title,
    required this.verdict,
  });

  final String subject;
  final String topic;
  final String title;
  final GuessNetVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final negative = verdict == GuessNetVerdict.negative;
    final bg = negative
        ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg)
        : (isDark ? AppColors.correctBgDark : AppColors.correctBg);
    final accent = negative
        ? (isDark ? AppColors.wrongTextDark : AppColors.wrong)
        : (isDark ? AppColors.correctTextDark : AppColors.correct);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                negative
                    ? Icons.warning_amber_rounded
                    : Icons.trending_up_rounded,
                size: 22,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  negative
                      ? context.l10n.practiceTopicGuessNegative
                      : context.l10n.practiceTopicGuessPositive,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: negative
                ? OutlinedButton(
                    onPressed: () => showInsightDrillSheet(
                      context,
                      target: InsightDrillTarget.topic(
                        subject: subject,
                        topicKey: topic,
                        title: title,
                        sureLens: false,
                      ),
                      intent: InsightDrillIntent.revise,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: Text(context.l10n.practiceReviseIncorrects),
                  )
                : FilledButton(
                    onPressed: () => showInsightDrillSheet(
                      context,
                      target: InsightDrillTarget.topic(
                        subject: subject,
                        topicKey: topic,
                        title: title,
                        sureLens: false,
                      ),
                      intent: InsightDrillIntent.improve,
                    ),
                    child: Text(context.l10n.practiceImproveScore),
                  ),
          ),
        ],
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
    return tabBar != oldDelegate.tabBar || background != oldDelegate.background;
  }
}

class _TopicList extends ConsumerWidget {
  const _TopicList({
    required this.subject,
    required this.sureLens,
    required this.topics,
    required this.lead,
    required this.empty,
  });

  final String subject;
  final bool sureLens;
  final List<LensTopic> topics;
  final String lead;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final language = watchAppLanguage(ref);
    final hindi = ref.watch(topicHindiNamesProvider).asData?.value;
    String titleOf(LensTopic topic) => localizedTopicName(
      topic.topicKey,
      language: language,
      hindiNames: hindi,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.md,
          ),
          child: Text(
            lead,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        if (topics.isEmpty)
          _EmptyNote(empty)
        else
          for (var i = 0; i < topics.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _TopicRow(
              topic: topics[i],
              onRevise: () => showInsightDrillSheet(
                context,
                target: InsightDrillTarget.topic(
                  subject: subject,
                  topicKey: topics[i].topicKey,
                  title: titleOf(topics[i]),
                  sureLens: sureLens,
                ),
                intent: InsightDrillIntent.revise,
              ),
              onImprove: () => showInsightDrillSheet(
                context,
                target: InsightDrillTarget.topic(
                  subject: subject,
                  topicKey: topics[i].topicKey,
                  title: titleOf(topics[i]),
                  sureLens: sureLens,
                ),
                intent: InsightDrillIntent.improve,
              ),
            ),
          ],
      ],
    );
  }
}

class _TrapsPreview extends StatelessWidget {
  const _TrapsPreview({required this.subject, this.topic, required this.traps});

  final String subject;
  final String? topic;
  final List<SubjectTrapStat> traps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = traps.take(_previewTrapCount).toList();
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
                  context.l10n.practiceTrapsTitleSure(traps.length),
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
            context.l10n.practiceTrapsLeadSure(
              topic == null
                  ? context.l10n.practiceTrapsScopeSubject
                  : context.l10n.practiceTrapsScopeTopic,
            ),
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < preview.length; i++) ...[
            _TrapPreviewRow(index: i, trap: preview[i]),
            if (i < preview.length - 1) const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final encodedSubject = Uri.encodeComponent(subject);
                final path = topic == null
                    ? '/subject/$encodedSubject/insights/traps'
                    : '/subject/$encodedSubject/topic/${Uri.encodeComponent(topic!)}/insights/traps';
                context.push(path);
              },
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

class _TrapPreviewRow extends ConsumerWidget {
  const _TrapPreviewRow({required this.index, required this.trap});

  final int index;
  final SubjectTrapStat trap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalog = ref.watch(trapDescriptionsProvider).asData?.value;
    final name = catalog?[trap.trapType]?.displayName ?? trap.title;
    final visual = TrapPatternVisual.of(trap.trapType);
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTextStyles.labelSm().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TrapInfoButton(trapType: trap.trapType, tooltip: name),
                      ],
                    ),
                  ),
                  Text(
                    context.l10n.practiceTrapsErrors(trap.wrong),
                    style: AppTextStyles.caption().copyWith(
                      color: visual.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicRow extends ConsumerWidget {
  const _TopicRow({
    required this.topic,
    required this.onRevise,
    required this.onImprove,
  });

  final LensTopic topic;
  final VoidCallback onRevise;
  final VoidCallback onImprove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = watchAppLanguage(ref);
    final hindi = ref.watch(topicHindiNamesProvider).asData?.value;
    final title = localizedTopicName(
      topic.topicKey,
      language: language,
      hindiNames: hindi,
    );
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
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRevise,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: Text(context.l10n.practiceReviseIncorrects),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: onImprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: Text(context.l10n.practiceImproveScore),
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
