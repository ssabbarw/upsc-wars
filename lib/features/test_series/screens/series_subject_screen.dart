import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/series_stats.dart';
import '../providers/test_series_providers.dart';
import '../widgets/series_dashboard_widgets.dart';
import '../widgets/series_tabs.dart';
import '../widgets/series_test_row.dart';
import '../../../l10n/l10n.dart';

/// One subject: accuracy, topics to revise / safe topics (from full-length and
/// subject-wise tests) and that subject's own tests.
class SeriesSubjectScreen extends ConsumerWidget {
  const SeriesSubjectScreen({
    super.key,
    required this.seriesId,
    required this.subjectId,
  });

  final String seriesId;
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(appLanguageProvider).asData?.value == 'hi';
    final owned =
        ref.watch(ownedSeriesIdsProvider).asData?.value.contains(seriesId) ??
        false;
    final bundleAsync = ref.watch(seriesBundleProvider(seriesId));
    final statsAsync = ref.watch(seriesStatsProvider(seriesId));
    final title = SeriesSubjects.label(subjectId, hindi: isHindi);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(context.l10n.tsLoadSubjectFail)),
        data: (bundle) {
          final stats =
              statsAsync.value ??
              SeriesStats.compute(
                bundle: bundle,
                attemptList: const [],
                answers: const [],
              );
          final subject = stats.core.subject(subjectId);
          if (subject == null) {
            return Center(child: Text(context.l10n.tsSubjectNotFound));
          }
          final tests = bundle.forBucket(subjectId);

          return RefreshIndicator(
            onRefresh: () async => refreshSeriesLocalState(ref, seriesId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _SubjectHeader(subject: subject, isHindi: isHindi),
                const SizedBox(height: AppSpacing.lg),
                SeriesTopicsPanel(
                  needsRevision: subject.needsRevision,
                  safeAreas: subject.safeAreas,
                  useConfidence: stats.core.useConfidence,
                  reviseTitle: context.l10n.tsTopicsToRevise,
                  isHindi: isHindi,
                  onTopicTap: (t) => openSeriesTopic(
                    context: context,
                    ref: ref,
                    bundle: bundle,
                    kinds: SeriesStats.coreKinds,
                    topic: t,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (tests.isNotEmpty) ...[
                  SeriesSectionHeader(context.l10n.tsTestsIn(title)),
                  for (final t in tests)
                    SeriesTestRow(
                      bundle: bundle,
                      test: t,
                      owned: owned,
                      stats: stats,
                    ),
                ] else
                  Text(
                    context.l10n.tsNoOwnTests,
                    style: AppTextStyles.bodySm().copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.subject, required this.isHindi});

  final SubjectStat subject;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = subject.answered > 0;
    final color = hasData
        ? seriesAccuracyColor(subject.accuracy)
        : scheme.onSurfaceVariant;
    final tests = subject.tests;
    final caption = tests != null
        ? context.l10n.tsCompletedOf(tests.attempted, tests.total)
        : hasData
        ? context.l10n.tsQAnswered(subject.answered)
        : context.l10n.tsNoQAnswered;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              seriesSubjectIcon(subject.subjectId),
              color: AppColors.info,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SeriesSubjects.label(subject.subjectId, hindi: isHindi),
                  style: AppTextStyles.h2(),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: tests?.fraction ?? (hasData ? subject.accuracy : 0),
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasData ? '${(subject.accuracy * 100).round()}%' : '—',
                style: AppTextStyles.h2().copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'accuracy',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
