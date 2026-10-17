import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/series_stats.dart';
import '../domain/start_series_topic_revision.dart';
import '../domain/test_series_models.dart';
import '../providers/test_series_providers.dart';
import 'free_badge.dart';
import 'series_dashboard_widgets.dart';
import 'series_paywall_sheet.dart';
import 'series_test_row.dart';

/// Opens the read-through of the user's questions on [topic].
void openSeriesTopic({
  required BuildContext context,
  required WidgetRef ref,
  required SeriesBundle bundle,
  required Set<String> kinds,
  required TopicStat topic,
}) {
  unawaited(
    startSeriesTopicRevision(
      context: context,
      ref: ref,
      bundle: bundle,
      kinds: kinds,
      subjectId: topic.subjectId,
      topic: topic.topic,
    ),
  );
}

/// Pull-to-refresh list shared by every tab.
class _TabList extends ConsumerWidget {
  const _TabList({required this.seriesId, required this.children});

  final String seriesId;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(seriesBundleProvider(seriesId));
        refreshSeriesLocalState(ref, seriesId);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ...children,
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _TabIntro extends StatelessWidget {
  const _TabIntro(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h1()),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.bodySm().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _marks(double net, double max) => '${net.round()}/${max.round()}';

/// Shown to people who have not unlocked the series.
class SeriesUnlockBanner extends ConsumerWidget {
  const SeriesUnlockBanner({super.key, required this.bundle});

  final SeriesBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSell = ref.watch(testSeriesCanSellProvider).value ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try the series',
            style: AppTextStyles.h3().copyWith(color: AppColors.primaryDeep),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Free tests are open now. Unlock the rest with one payment: '
            'no subscription, no expiry.',
            style: AppTextStyles.bodySm().copyWith(
              color: AppColors.primaryDeep,
            ),
          ),
          if (canSell) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => unawaited(
                showSeriesPaywall(context: context, bundle: bundle),
              ),
              child: const Text('Unlock all tests'),
            ),
          ],
        ],
      ),
    );
  }
}

/// "What you get" card on the Overview: the series' selling points, with real
/// counts from the published series.
class SeriesUspCard extends StatelessWidget {
  const SeriesUspCard({super.key, required this.bundle});

  final SeriesBundle bundle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flt = bundle.ofKind(SeriesTestKind.fullLength).length;
    final subject = bundle.ofKind(SeriesTestKind.staticTest).length;
    final pyq = bundle.ofKind(SeriesTestKind.pyqMix).length;

    Widget row(
      IconData icon,
      Color color,
      String title,
      String body, {
      bool free = false,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMd().copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (free) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const FreeBadge(size: 34),
                        ],
                      ],
                    ),
                    Text(
                      body,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What you get', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.md),
          row(
            Icons.timer_outlined,
            AppColors.primary,
            '$flt full-length mocks',
            'Each test has 100 questions, Time 2 hours.\nTest of all GS subjects + current affairs',
          ),
          row(
            Icons.menu_book_rounded,
            AppColors.info,
            '$subject subject tests',
            'Topic-wise 50-question tests for GS subjects',
          ),
          row(
            Icons.newspaper_rounded,
            AppColors.info,
            'Current affairs every month',
            'A fresh test on the 1st of each month, built from the previous month\'s Current affairs.',
          ),
          row(
            Icons.history_edu_rounded,
            AppColors.warning,
            'Previous year questions',
            '$pyq free PYQ mix tests',
            free: true,
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Divider(height: 1),
          ),
          row(
            Icons.insights_rounded,
            AppColors.primary,
            'Know where you lose marks',
            'Accuracy by subject, topics to revise and safe areas, based on '
                'how sure you were.',
          ),
          row(
            Icons.translate_rounded,
            AppColors.info,
            'Hindi and English, one payment',
            'No subscription. Pay once and it never expires.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Overview
// ─────────────────────────────────────────────────────────────────────────

class SeriesOverviewTab extends ConsumerWidget {
  const SeriesOverviewTab({
    super.key,
    required this.bundle,
    required this.owned,
    required this.isHindi,
    required this.stats,
  });

  final SeriesBundle bundle;
  final bool owned;
  final bool isHindi;
  final SeriesStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = stats.core;
    final controller = DefaultTabController.of(context);
    final flts = bundle.ofKind(SeriesTestKind.fullLength);
    final listed = [
      for (final id in SeriesSubjects.alwaysListed) core.subject(id)!,
    ];

    void onTopic(TopicStat t) => openSeriesTopic(
      context: context,
      ref: ref,
      bundle: bundle,
      kinds: SeriesStats.coreKinds,
      topic: t,
    );

    void openAll({required bool revise}) {
      unawaited(
        showSeriesTopicsSheet(
          context: context,
          title: revise ? 'Needs revision' : 'Safe areas',
          subtitle: revise
              ? (core.useConfidence
                    ? 'Questions you got wrong despite high confidence.'
                    : 'Questions you got wrong. Tap a topic to read them again.')
              : 'Topics you answer reliably across your tests.',
          topics: revise ? core.needsRevision : core.safeAreas,
          revise: revise,
          showSubject: true,
          isHindi: isHindi,
          onTopicTap: onTopic,
        ),
      );
    }

    return _TabList(
      seriesId: bundle.info.id,
      children: [
        if (!owned) SeriesUnlockBanner(bundle: bundle),
        _TabIntro(
          'Your Preparation Overview',
          stats.hasAnyAttempt
              ? 'Based on your full-length and subject-wise tests.'
              : 'Finish a test to see your progress, weak topics and strengths.',
        ),
        if (!owned || !stats.hasAnyAttempt) ...[
          SeriesUspCard(bundle: bundle),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (!stats.hasAnyAttempt) ...[
          Text(
            'YOUR STATS',
            style: AppTextStyles.caption().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Before the first test the tiles are shown dimmed as a preview.
        Opacity(
          opacity: stats.hasAnyAttempt ? 1 : 0.5,
          child: IgnorePointer(
            ignoring: !stats.hasAnyAttempt,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SeriesStatTile(
                        icon: Icons.assignment_turned_in_rounded,
                        color: AppColors.primary,
                        value: '${core.tests.attempted}/${core.tests.total}',
                        label: 'Tests completed',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SeriesStatTile(
                        icon: Icons.track_changes_rounded,
                        color: AppColors.primary,
                        value: core.answered == 0
                            ? '—'
                            : '${(core.accuracy * 100).round()}%',
                        label: 'Overall accuracy',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SeriesStatTile(
                        icon: Icons.quiz_rounded,
                        color: AppColors.info,
                        value: '${core.answered}',
                        label: 'Questions attempted',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SeriesStatTile(
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.warning,
                        value: core.attemptCount == 0
                            ? '—'
                            : _marks(core.bestNet, core.bestMax),
                        label: 'Best test score',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Equal-height cards: a stretching Row needs a bounded height,
                // which a scrolling list does not give it.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SeriesInsightCard(
                          revise: true,
                          count: core.needsRevision.length,
                          caption: core.useConfidence
                              ? 'Confident mistakes'
                              : 'Mistakes',
                          action: 'Topics to revise first',
                          onTap: () => openAll(revise: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SeriesInsightCard(
                          revise: false,
                          count: core.safeAreas.length,
                          caption: 'Reliable topics',
                          action: 'Keep practising',
                          onTap: () => openAll(revise: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SeriesSectionHeader(
          'Full-Length Tests',
          actionLabel: 'See all',
          onAction: () => controller.animateTo(1),
        ),
        for (final t in flts.take(3))
          SeriesTestRow(bundle: bundle, test: t, owned: owned, stats: stats),
        const SizedBox(height: AppSpacing.lg),
        SeriesSectionHeader(
          'Subject-wise Performance',
          actionLabel: 'See all',
          onAction: () => controller.animateTo(2),
        ),
        for (final s in listed.take(3))
          SeriesSubjectRow(
            stat: s,
            isHindi: isHindi,
            onTap: () => unawaited(
              context.push(
                '/test-series/${bundle.info.id}/subject/${s.subjectId}',
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Full-length tests
// ─────────────────────────────────────────────────────────────────────────

class SeriesFullLengthTab extends ConsumerWidget {
  const SeriesFullLengthTab({
    super.key,
    required this.bundle,
    required this.owned,
    required this.isHindi,
    required this.stats,
  });

  final SeriesBundle bundle;
  final bool owned;
  final bool isHindi;
  final SeriesStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flt = stats.flt;
    final tests = bundle.ofKind(SeriesTestKind.fullLength);

    return _TabList(
      seriesId: bundle.info.id,
      children: [
        const _TabIntro(
          'Full-Length Tests',
          'Simulate the real exam: 100 questions, 2 hours.',
        ),
        Row(
          children: [
            Expanded(
              child: SeriesStatTile(
                icon: Icons.assignment_turned_in_rounded,
                color: AppColors.primary,
                value: '${flt.tests.attempted}/${flt.tests.total}',
                label: 'Completed',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SeriesStatTile(
                icon: Icons.speed_rounded,
                color: AppColors.info,
                value: flt.attemptCount == 0
                    ? '—'
                    : _marks(flt.avgNet, flt.avgMax),
                label: 'Average score',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SeriesStatTile(
                icon: Icons.emoji_events_rounded,
                color: AppColors.warning,
                value: flt.attemptCount == 0
                    ? '—'
                    : _marks(flt.bestNet, flt.bestMax),
                label: 'Best score',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SeriesTopicsPanel(
          needsRevision: flt.needsRevision,
          safeAreas: flt.safeAreas,
          useConfidence: flt.useConfidence,
          reviseTitle: 'Topics to revise (from FLTs)',
          showSubject: true,
          isHindi: isHindi,
          onTopicTap: (t) => openSeriesTopic(
            context: context,
            ref: ref,
            bundle: bundle,
            kinds: SeriesStats.fltKinds,
            topic: t,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SeriesSectionHeader('Available Tests'),
        for (final t in tests)
          SeriesTestRow(bundle: bundle, test: t, owned: owned, stats: stats),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Subject-wise tests
// ─────────────────────────────────────────────────────────────────────────

class SeriesSubjectsTab extends ConsumerWidget {
  const SeriesSubjectsTab({
    super.key,
    required this.bundle,
    required this.owned,
    required this.isHindi,
    required this.stats,
  });

  final SeriesBundle bundle;
  final bool owned;
  final bool isHindi;
  final SeriesStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final full = bundle.forBucket(SeriesBuckets.fullSyllabus);
    final rows = [
      for (final s in stats.core.subjects)
        if (SeriesSubjects.alwaysListed.contains(s.subjectId) || s.answered > 0)
          s,
    ];

    return _TabList(
      seriesId: bundle.info.id,
      children: [
        const _TabIntro(
          'Subject-wise Tests',
          'Practise by subject and strengthen your concepts.',
        ),
        if (full.isNotEmpty) ...[
          SeriesSectionHeader(
            'Full Syllabus Tests',
            trailingText:
                '${full.where((t) => stats.attempts.containsKey(t.id)).length}/${full.length} done',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Every subject in one paper, in Prelims proportion.',
              style: AppTextStyles.bodySm().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final t in full)
            SeriesTestRow(bundle: bundle, test: t, owned: owned, stats: stats),
          const SizedBox(height: AppSpacing.lg),
          const SeriesSectionHeader('By subject'),
        ],
        for (final s in rows)
          SeriesSubjectRow(
            stat: s,
            isHindi: isHindi,
            onTap: () => unawaited(
              context.push(
                '/test-series/${bundle.info.id}/subject/${s.subjectId}',
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PYQ & current affairs
// ─────────────────────────────────────────────────────────────────────────

class SeriesPyqCaTab extends ConsumerWidget {
  const SeriesPyqCaTab({
    super.key,
    required this.bundle,
    required this.owned,
    required this.stats,
  });

  final SeriesBundle bundle;
  final bool owned;
  final SeriesStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pyq = bundle.ofKind(SeriesTestKind.pyqMix);
    final ca = bundle.ofKind(SeriesTestKind.currentAffairs);

    return _TabList(
      seriesId: bundle.info.id,
      children: [
        const _TabIntro(
          'PYQ & Current Affairs',
          'Extra practice. These tests are not counted in your overview stats.',
        ),
        if (pyq.isNotEmpty) ...[
          SeriesSectionHeader(
            'Previous year questions',
            trailingText:
                '${stats.pyqTests.attempted}/${stats.pyqTests.total} done',
          ),
          for (final t in pyq)
            SeriesTestRow(bundle: bundle, test: t, owned: owned, stats: stats),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (ca.isNotEmpty) ...[
          SeriesSectionHeader(
            'Current affairs',
            trailingText:
                '${stats.caTests.attempted}/${stats.caTests.total} done',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'A new test arrives on the 1st of each month.',
              style: AppTextStyles.bodySm().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final t in ca)
            SeriesTestRow(bundle: bundle, test: t, owned: owned, stats: stats),
        ],
      ],
    );
  }
}
