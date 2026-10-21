import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../practice_tests/domain/practice_scope.dart';
import '../../practice_tests/providers/practice_catalog_provider.dart';
import '../../subject_detail/providers/subject_insights_providers.dart';
import '../../subject_detail/providers/subject_scored_accuracy_provider.dart';
import '../../subject_detail/widgets/danger_zone_summary_card.dart';
import '../domain/focus_recommendations.dart';
import '../widgets/stats_charts.dart';
import '../widgets/stats_locked_section.dart';

enum _TopicSort { weakest, leastCovered, az }

class StatsScreen extends HookConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = GoRouterState.of(context).uri.queryParameters['subject'];
    final catalog = ref.watch(practiceCatalogProvider);
    final sort = useState(_TopicSort.weakest);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    useEffect(() {
      unawaited(
        Analytics.track(ref, StatsViewedEvent(subject: selected ?? 'all')),
      );
      return null;
    }, [selected]);

    return Scaffold(
      body: SafeArea(
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(practiceCatalogProvider),
              child: Text(context.l10n.commonRetry),
            ),
          ),
          data: (data) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  context.l10n.statsTitle,
                  style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.md),
                _Pills(
                  selected: selected,
                  onSelect: (slug) {
                    if (slug == null) {
                      context.go('/stats');
                    } else {
                      context.go(
                        '/stats?subject=${Uri.encodeQueryComponent(slug)}',
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selected == null)
                  _AllSubjects(catalog: data, border: border)
                else
                  _OneSubject(
                    subject: selected,
                    catalog: data,
                    border: border,
                    sort: sort.value,
                    onSort: (value) => sort.value = value,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            label: context.l10n.statsAllSubjects,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final def in SubjectConstants.ordered) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(
              label: def.displayName,
              selected: selected == def.slug,
              onTap: () => onSelect(def.slug),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      labelStyle: AppTextStyles.caption().copyWith(
        color: selected ? AppColors.primary : scheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _AllSubjects extends ConsumerWidget {
  const _AllSubjects({required this.catalog, required this.border});

  final PracticeCatalog catalog;
  final Color border;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var pool = 0;
    var answered = 0;
    var correct = 0;
    var done = 0;
    var total = 0;
    for (final progress in catalog.subjectProgress.values) {
      pool += progress.poolSize;
      answered += progress.answered;
      correct += progress.correct;
      done += progress.testsDone;
      total += progress.testsTotal;
    }
    final overall = PracticeScopeProgress(
      testsDone: done,
      testsTotal: total,
      poolSize: pool,
      answered: answered,
      correct: correct,
    );
    final focus = _focus(catalog);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hero(progress: overall, border: border),
        const SizedBox(height: AppSpacing.md),
        StatsBarChart(
          title: context.l10n.statsAccuracyChart,
          border: border,
          bars: [
            for (final def in SubjectConstants.ordered)
              _bar(
                context,
                label: def.displayName,
                progress:
                    catalog.subjectProgress[def.slug] ??
                    PracticeScopeProgress.empty,
                onTap: () => context.go(
                  '/stats?subject=${Uri.encodeQueryComponent(def.slug)}',
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _FocusCard(
          items: focus.take(3).toList(),
          catalog: catalog,
          border: border,
        ),
        const SizedBox(height: AppSpacing.md),
        _TrapCard(border: border),
      ],
    );
  }
}

class _OneSubject extends ConsumerWidget {
  const _OneSubject({
    required this.subject,
    required this.catalog,
    required this.border,
    required this.sort,
    required this.onSort,
  });

  final String subject;
  final PracticeCatalog catalog;
  final Color border;
  final _TopicSort sort;
  final ValueChanged<_TopicSort> onSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        catalog.subjectProgress[subject] ?? PracticeScopeProgress.empty;
    final insights = ref.watch(subjectInsightsProvider(subject));
    final accuracy = ref.watch(subjectScoredAccuracyProvider(subject));
    final def = SubjectConstants.bySlug(subject);
    final topics = (catalog.topicProgress[subject] ?? const {}).entries
        .toList();
    topics.sort((a, b) {
      switch (sort) {
        case _TopicSort.weakest:
          final aa = a.value.accuracyPercent ?? 101;
          final bb = b.value.accuracyPercent ?? 101;
          return aa.compareTo(bb);
        case _TopicSort.leastCovered:
          final aa = a.value.coveragePercent ?? 101;
          final bb = b.value.coveragePercent ?? 101;
          return aa.compareTo(bb);
        case _TopicSort.az:
          final an = catalog.topicDisplayNames[a.key] ?? a.key;
          final bn = catalog.topicDisplayNames[b.key] ?? b.key;
          return an.toLowerCase().compareTo(bn.toLowerCase());
      }
    });
    final focus = _focus(catalog, subject: subject);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatsLockedSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(progress: progress, border: border),
              const SizedBox(height: AppSpacing.sm),
              accuracy.maybeWhen(
                data: (summary) => Text(
                  context.l10n.statsConfidence(
                    summary.sureTotal,
                    summary.sureWrong,
                    summary.educatedGuessTotal,
                    summary.educatedGuessWrong,
                  ),
                  style: AppTextStyles.caption().copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.md),
              _FocusCard(items: focus, catalog: catalog, border: border),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _SortChip(
                    label: context.l10n.statsSortWeakest,
                    selected: sort == _TopicSort.weakest,
                    onTap: () => onSort(_TopicSort.weakest),
                  ),
                  _SortChip(
                    label: context.l10n.statsSortLeastCovered,
                    selected: sort == _TopicSort.leastCovered,
                    onTap: () => onSort(_TopicSort.leastCovered),
                  ),
                  _SortChip(
                    label: context.l10n.statsSortAz,
                    selected: sort == _TopicSort.az,
                    onTap: () => onSort(_TopicSort.az),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StatsBarChart(
                title: context.l10n.statsTopicChart,
                border: border,
                bars: [
                  for (final entry in topics)
                    _bar(
                      context,
                      label: catalog.topicDisplayNames[entry.key] ?? entry.key,
                      progress: entry.value,
                      onTap: () => context.push(
                        '/subject/${Uri.encodeComponent(subject)}/topic/${Uri.encodeComponent(entry.key)}/tests',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        insights.maybeWhen(
          data: (value) => DangerZoneSummaryCard(
            dangerZoneContextLabel: def?.displayName ?? subject,
            subject: subject,
            insights: value,
            borderColor: border,
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.progress, required this.border});

  final PracticeScopeProgress progress;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return StatsHero(
      progress: progress,
      border: border,
      coverageLabel: context.l10n.statsRingCoverage,
      accuracyLabel: context.l10n.statsAccuracyLabel,
      testsLabel: context.l10n.statsRingTests,
      answeredLabel: context.l10n.statsAnswered(progress.answered),
    );
  }
}

StatsBar _bar(
  BuildContext context, {
  required String label,
  required PracticeScopeProgress progress,
  required VoidCallback onTap,
}) {
  String pct(double? value) => value == null ? '—' : '${value.round()}%';
  return StatsBar(
    label: label,
    accuracy: progress.accuracyPercent,
    detail:
        '${context.l10n.statsCoverage(pct(progress.coveragePercent))}'
        ' · ${context.l10n.practiceTestsProgress(progress.testsDone, progress.testsTotal)}',
    onTap: onTap,
  );
}

class _FocusCard extends ConsumerWidget {
  const _FocusCard({
    required this.items,
    required this.catalog,
    required this.border,
  });

  final List<FocusRecommendation> items;
  final PracticeCatalog catalog;
  final Color border;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.statsFocusNext,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Text(
              context.l10n.statsFocusEmpty,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_label(context, item)),
              subtitle: Text(
                SubjectConstants.bySlug(item.subject)?.displayName ??
                    item.subject,
              ),
              onTap: () {
                unawaited(
                  Analytics.track(
                    ref,
                    StatsFocusTapEvent(
                      subject: item.subject,
                      topic: item.topic,
                    ),
                  ),
                );
                context.push(
                  '/subject/${Uri.encodeComponent(item.subject)}/topic/${Uri.encodeComponent(item.topic)}/tests',
                );
              },
            ),
        ],
      ),
    );
  }

  String _label(BuildContext context, FocusRecommendation item) {
    switch (item.kind) {
      case FocusKind.weak:
        return context.l10n.statsFocusRevise(item.displayName);
      case FocusKind.shaky:
        return context.l10n.statsFocusPractise(item.displayName);
      case FocusKind.untouched:
        return context.l10n.statsFocusStart(item.displayName);
    }
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TrapCard extends ConsumerWidget {
  const _TrapCard({required this.border});

  final Color border;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => context.push('/weak-areas/traps'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.statsTrapPatterns,
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<FocusRecommendation> _focus(PracticeCatalog catalog, {String? subject}) {
  final candidates = <FocusCandidate>[];
  for (final subjectEntry in catalog.topicProgress.entries) {
    for (final topicEntry in subjectEntry.value.entries) {
      final progress = topicEntry.value;
      candidates.add(
        FocusCandidate(
          subject: subjectEntry.key,
          topic: topicEntry.key,
          displayName:
              catalog.topicDisplayNames[topicEntry.key] ?? topicEntry.key,
          poolSize: progress.poolSize,
          answered: progress.answered,
          correct: progress.correct,
        ),
      );
    }
  }
  return focusRecommendations(candidates, subject: subject, limit: 3);
}
