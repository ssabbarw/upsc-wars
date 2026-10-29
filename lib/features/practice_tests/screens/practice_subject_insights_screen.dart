import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_subject_insights.dart';
import '../domain/practice_topic_visual.dart';
import '../providers/practice_catalog_provider.dart';
import '../providers/practice_subject_insights_provider.dart';
import '../widgets/practice_insight_charts.dart';
import '../widgets/practice_pattern_sheet.dart';
import '../widgets/practice_snapshot_card.dart';
import '../widgets/practice_test_tile.dart';

/// Sure vs Educated-guess verdicts, with topic lists to revise.
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
      length: 2,
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
              data: (value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: PracticeSnapshotCard(
                      progress: progress,
                      insights: AsyncValue.data(value),
                      ctaLabel: context.l10n.practiceSnapshotSeePatterns,
                      ctaFilled: true,
                      onCta: value.patterns.isEmpty
                          ? null
                          : () => showPracticePatternSheet(
                              context: context,
                              subject: subject,
                              patterns: value.patterns,
                            ),
                    ),
                  ),
                  TabBar(
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    labelColor: scheme.onSurface,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    labelStyle: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: AppTextStyles.label(),
                    dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
                    tabs: [
                      Tab(text: context.l10n.practiceLensSure),
                      Tab(text: context.l10n.practiceLensGuess),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _LensTab(
                          band: value.sureBand,
                          headline: _sureHeadline(context, value.sureBand),
                          body: _sureBody(context, value.sureBand),
                          correct: value.sureCorrect,
                          wrong: value.sureWrong,
                          empty: context.l10n.practiceSureTopicsEmpty,
                          topics: value.sureTopics,
                          onRevise: (topic) => _reviseTopic(
                            context,
                            ref,
                            catalog: data,
                            subject: subject,
                            topicKey: topic,
                          ),
                        ),
                        _LensTab(
                          band: value.guessBand,
                          headline: _guessHeadline(context, value.guessBand),
                          body: _guessBody(context, value.guessBand),
                          correct: value.educatedGuessCorrect,
                          wrong: value.educatedGuessWrong,
                          empty: context.l10n.practiceGuessTopicsEmpty,
                          topics: value.guessTopics,
                          onRevise: (topic) => _reviseTopic(
                            context,
                            ref,
                            catalog: data,
                            subject: subject,
                            topicKey: topic,
                          ),
                        ),
                      ],
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

String _sureHeadline(BuildContext context, InsightBand band) {
  switch (band) {
    case InsightBand.bad:
      return context.l10n.practiceSureSnapBad;
    case InsightBand.mixed:
      return context.l10n.practiceSureSnapMixed;
    case InsightBand.good:
      return context.l10n.practiceSureSnapGood;
    case InsightBand.thin:
      return context.l10n.practiceSureSnapThin;
  }
}

String _sureBody(BuildContext context, InsightBand band) {
  switch (band) {
    case InsightBand.bad:
      return context.l10n.practiceSureBodyBad;
    case InsightBand.mixed:
      return context.l10n.practiceSureBodyMixed;
    case InsightBand.good:
      return context.l10n.practiceSureBodyGood;
    case InsightBand.thin:
      return context.l10n.practiceSureBodyThin;
  }
}

String _guessHeadline(BuildContext context, InsightBand band) {
  switch (band) {
    case InsightBand.bad:
      return context.l10n.practiceGuessSnapBad;
    case InsightBand.mixed:
      return context.l10n.practiceGuessSnapMixed;
    case InsightBand.good:
      return context.l10n.practiceGuessSnapGood;
    case InsightBand.thin:
      return context.l10n.practiceGuessSnapThin;
  }
}

String _guessBody(BuildContext context, InsightBand band) {
  switch (band) {
    case InsightBand.bad:
      return context.l10n.practiceGuessBodyBad;
    case InsightBand.mixed:
      return context.l10n.practiceGuessBodyMixed;
    case InsightBand.good:
      return context.l10n.practiceGuessBodyGood;
    case InsightBand.thin:
      return context.l10n.practiceGuessBodyThin;
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

class _LensTab extends StatelessWidget {
  const _LensTab({
    required this.band,
    required this.headline,
    required this.body,
    required this.correct,
    required this.wrong,
    required this.empty,
    required this.topics,
    required this.onRevise,
  });

  final InsightBand band;
  final String headline;
  final String body;
  final int correct;
  final int wrong;
  final String empty;
  final List<LensTopic> topics;
  final ValueChanged<String> onRevise;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _VerdictBanner(
          band: band,
          headline: headline,
          body: body,
          correct: correct,
          wrong: wrong,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (topics.isEmpty)
          _EmptyNote(empty)
        else
          for (final topic in topics) ...[
            _TopicRow(topic: topic, onRevise: () => onRevise(topic.topicKey)),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({
    required this.band,
    required this.headline,
    required this.body,
    required this.correct,
    required this.wrong,
  });

  final InsightBand band;
  final String headline;
  final String body;
  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = insightBandColor(band, isDark: isDark);
    final total = correct + wrong;
    final rightShare = total == 0 ? 0.0 : correct / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: insightBandFill(band, isDark: isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.28 : 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_bannerIcon(band), size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  headline,
                  style: AppTextStyles.label().copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: rightShare,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.gray800 : AppColors.gray50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(
                color: AppColors.primary,
                label: '${context.l10n.practiceLensRight} $correct',
              ),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(
                color: AppColors.wrong,
                label: '${context.l10n.practiceLensWrong} $wrong',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _bannerIcon(InsightBand band) {
  switch (band) {
    case InsightBand.bad:
      return Icons.error_outline_rounded;
    case InsightBand.mixed:
      return Icons.priority_high_rounded;
    case InsightBand.good:
      return Icons.check_rounded;
    case InsightBand.thin:
      return Icons.info_outline_rounded;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
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
