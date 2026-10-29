import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/presentation/topic_label.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/trap_descriptions_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../weak_areas/widgets/trap_info_button.dart';
import '../../weak_areas/widgets/trap_pattern_visual.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_subject_insights.dart';
import '../domain/practice_topic_visual.dart';
import '../open_insight_practice.dart';
import '../providers/practice_catalog_provider.dart';
import '../providers/practice_subject_insights_provider.dart';
import 'practice_snapshot_card.dart';

const _previewTrapCount = 3;

/// Accuracy, Sure / educated guess, traps, and confident / guess mistakes.
///
/// [primaryScroll] owns the scroll view (subject and topic screens, or one
/// subject on Stats). Set it false to drop this into a parent list, which
/// stacks confident mistakes and guess mistakes instead of using tabs.
class PracticeSubjectInsightsView extends ConsumerWidget {
  const PracticeSubjectInsightsView({
    super.key,
    required String subject,
    this.topic,
    this.primaryScroll = true,
  }) : subject = subject,
       allSubjects = false;

  /// One season view: ratings and traps across every subject, with confident
  /// mistakes and guesses listed by subject.
  const PracticeSubjectInsightsView.all({super.key, this.primaryScroll = true})
    : subject = null,
      topic = null,
      allSubjects = true;

  final String? subject;
  final String? topic;
  final bool primaryScroll;
  final bool allSubjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(practiceCatalogProvider);
    final displayName = allSubjects
        ? context.l10n.statsAllSubjects
        : topic == null
        ? (SubjectConstants.bySlug(subject!)?.displayName ?? subject!)
        : (catalog.asData?.value.topicDisplayNames[topic] ?? topic!);
    final insights = allSubjects
        ? ref.watch(practiceAllSubjectsInsightsProvider)
        : topic == null
        ? ref.watch(practiceSubjectInsightsProvider(subject!))
        : ref.watch(
            practiceTopicInsightsProvider((subject: subject!, topic: topic!)),
          );

    void reloadInsights() {
      if (allSubjects) {
        ref.invalidate(practiceAllSubjectsInsightsProvider);
      } else if (topic == null) {
        ref.invalidate(practiceSubjectInsightsProvider(subject!));
      } else {
        ref.invalidate(
          practiceTopicInsightsProvider((subject: subject!, topic: topic!)),
        );
      }
    }

    Widget retry(VoidCallback onPressed) {
      return TextButton(
        onPressed: onPressed,
        child: Text(context.l10n.commonRetry),
      );
    }

    return catalog.when(
      loading: () => _InsightsBusy(expand: primaryScroll),
      error: (_, _) => _InsightsMessage(
        expand: primaryScroll,
        child: retry(() => ref.invalidate(practiceCatalogProvider)),
      ),
      data: (data) {
        final progress = allSubjects
            ? _overallProgress(data)
            : topic == null
            ? (data.subjectProgress[subject!] ?? PracticeScopeProgress.empty)
            : (data.topicProgress[subject!]?[topic] ??
                  PracticeScopeProgress.empty);
        return insights.when(
          loading: () => _InsightsBusy(expand: primaryScroll),
          error: (_, _) => _InsightsMessage(
            expand: primaryScroll,
            child: retry(reloadInsights),
          ),
          data: (value) {
            final lead = _InsightsLead(
              subject: subject,
              topic: topic,
              allSubjects: allSubjects,
              displayName: displayName,
              progress: progress,
              insights: value,
            );
            final sureLead = allSubjects
                ? context.l10n.practiceSureSubjectsLead
                : context.l10n.practiceSureTopicsLead(displayName);
            final guessLead = allSubjects
                ? context.l10n.practiceGuessSubjectsLead
                : context.l10n.practiceGuessTopicsLead(displayName);
            final sureEmpty = allSubjects
                ? context.l10n.practiceSureSubjectsEmpty
                : context.l10n.practiceSureTopicsEmpty;
            final guessEmpty = allSubjects
                ? context.l10n.practiceGuessSubjectsEmpty
                : context.l10n.practiceGuessTopicsEmpty;
            if (topic != null) {
              return _scrollOrColumn(
                primaryScroll: primaryScroll,
                children: [_paddedLead(lead)],
              );
            }
            if (!primaryScroll) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _paddedLead(lead),
                  _TopicList(
                    subject: subject,
                    sureLens: true,
                    subjectRows: allSubjects,
                    topics: value.sureTopics,
                    sectionTitle: context.l10n.practiceLensTabSure,
                    lead: sureLead,
                    empty: sureEmpty,
                    primaryScroll: false,
                  ),
                  _TopicList(
                    subject: subject,
                    sureLens: false,
                    subjectRows: allSubjects,
                    topics: value.guessTopics,
                    sectionTitle: context.l10n.practiceLensTabGuess,
                    lead: guessLead,
                    empty: guessEmpty,
                    primaryScroll: false,
                  ),
                ],
              );
            }
            return DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(child: _paddedLead(lead)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TopicTabBarDelegate(
                      background: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      tabBar: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        labelColor: Theme.of(context).colorScheme.onSurface,
                        unselectedLabelColor: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        labelStyle: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: AppTextStyles.label(),
                        dividerColor: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
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
                      subjectRows: allSubjects,
                      topics: value.sureTopics,
                      lead: sureLead,
                      empty: sureEmpty,
                    ),
                    _TopicList(
                      subject: subject,
                      sureLens: false,
                      subjectRows: allSubjects,
                      topics: value.guessTopics,
                      lead: guessLead,
                      empty: guessEmpty,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Widget _paddedLead(Widget child) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: child,
  );
}

PracticeScopeProgress _overallProgress(PracticeCatalog data) {
  var pool = 0;
  var answered = 0;
  var correct = 0;
  var done = 0;
  var total = 0;
  for (final progress in data.subjectProgress.values) {
    pool += progress.poolSize;
    answered += progress.answered;
    correct += progress.correct;
    done += progress.testsDone;
    total += progress.testsTotal;
  }
  return PracticeScopeProgress(
    testsDone: done,
    testsTotal: total,
    poolSize: pool,
    answered: answered,
    correct: correct,
  );
}

Widget _scrollOrColumn({
  required bool primaryScroll,
  required List<Widget> children,
}) {
  if (!primaryScroll) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
  return ListView(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
    children: children,
  );
}

class _InsightsBusy extends StatelessWidget {
  const _InsightsBusy({required this.expand});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _InsightsMessage(
      expand: expand,
      child: const CircularProgressIndicator(),
    );
  }
}

class _InsightsMessage extends StatelessWidget {
  const _InsightsMessage({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (expand) return Center(child: child);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Align(alignment: Alignment.center, heightFactor: 1, child: child),
    );
  }
}

class _InsightsLead extends StatelessWidget {
  const _InsightsLead({
    required this.subject,
    this.topic,
    this.allSubjects = false,
    required this.displayName,
    required this.progress,
    required this.insights,
  });

  final String? subject;
  final String? topic;
  final bool allSubjects;
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
          allSubjects
              ? context.l10n.practiceStatsSourcesAll
              : context.l10n.practiceStatsSourcesNote(displayName),
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (guessVerdict != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _TopicGuessVerdictCard(
            subject: subject!,
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
            allSubjects: allSubjects,
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
    this.subjectRows = false,
    this.sectionTitle,
    this.primaryScroll = true,
  });

  final String? subject;
  final bool sureLens;
  final bool subjectRows;
  final List<LensTopic> topics;
  final String lead;
  final String empty;
  final String? sectionTitle;
  final bool primaryScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final language = watchAppLanguage(ref);
    final hindi = ref.watch(topicHindiNamesProvider).asData?.value;
    String titleOf(LensTopic topic) => subjectRows
        ? topic.displayName
        : localizedTopicName(
            topic.topicKey,
            language: language,
            hindiNames: hindi,
          );
    final children = <Widget>[
      if (sectionTitle != null)
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            sectionTitle!,
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
            title: titleOf(topics[i]),
            subjectRow: subjectRows,
            onOpen: subjectRows
                ? () => context.go(
                    '/stats?subject=${Uri.encodeQueryComponent(topics[i].topicKey)}',
                  )
                : null,
            onRevise: subjectRows
                ? null
                : () => showInsightDrillSheet(
                    context,
                    target: InsightDrillTarget.topic(
                      subject: subject!,
                      topicKey: topics[i].topicKey,
                      title: titleOf(topics[i]),
                      sureLens: sureLens,
                    ),
                    intent: InsightDrillIntent.revise,
                  ),
            onImprove: subjectRows
                ? null
                : () => showInsightDrillSheet(
                    context,
                    target: InsightDrillTarget.topic(
                      subject: subject!,
                      topicKey: topics[i].topicKey,
                      title: titleOf(topics[i]),
                      sureLens: sureLens,
                    ),
                    intent: InsightDrillIntent.improve,
                  ),
          ),
        ],
    ];
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      primaryScroll ? AppSpacing.xxxl : AppSpacing.lg,
    );
    if (!primaryScroll) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }
    return ListView(padding: padding, children: children);
  }
}

class _TrapsPreview extends StatelessWidget {
  const _TrapsPreview({
    required this.subject,
    this.topic,
    this.allSubjects = false,
    required this.traps,
  });

  final String? subject;
  final String? topic;
  final bool allSubjects;
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
            allSubjects
                ? context.l10n.practiceTrapsLeadAll
                : context.l10n.practiceTrapsLeadSure(
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
            _TrapPreviewRow(trap: preview[i]),
            if (i < preview.length - 1) const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (allSubjects || subject == null) {
                  context.push('/stats/traps');
                  return;
                }
                final encodedSubject = Uri.encodeComponent(subject!);
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
  const _TrapPreviewRow({required this.trap});

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

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.title,
    this.subjectRow = false,
    this.onOpen,
    this.onRevise,
    this.onImprove,
  });

  final LensTopic topic;
  final String title;
  final bool subjectRow;
  final VoidCallback? onOpen;
  final VoidCallback? onRevise;
  final VoidCallback? onImprove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = subjectRow
        ? _subjectVisual(topic.topicKey)
        : practiceTopicVisual(topic.topicKey, isDark: isDark);
    final wrongColor = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    final card = Container(
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
                if (onRevise != null && onImprove != null) ...[
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
              ],
            ),
          ),
          if (onOpen != null)
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
    if (onOpen == null) return card;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: card,
      ),
    );
  }
}

PracticeTopicVisual _subjectVisual(String slug) {
  const accents = <Color>[
    AppColors.info,
    AppColors.warning,
    AppColors.gold,
    AppColors.primary,
    AppColors.correct,
    AppColors.wrong,
    AppColors.purple,
  ];
  final index = SubjectConstants.ordered.indexWhere((s) => s.slug == slug);
  final accent =
      accents[(index < 0 ? slug.hashCode.abs() : index) % accents.length];
  return PracticeTopicVisual(
    icon: SubjectConstants.bySlug(slug)?.materialIcon ?? Icons.school_outlined,
    accent: accent,
  );
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
