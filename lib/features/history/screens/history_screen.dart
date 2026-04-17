import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/domain/entities/session_summary.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/extensions/time_formatting.dart';
import '../providers/history_filters_provider.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(historyFilterStateProvider);
    final async = ref.watch(
      sessionSummariesProvider(subject: filters.subject, mode: filters.mode),
    );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: async.when(
                data: (list) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History', style: AppTextStyles.h2().copyWith(color: scheme.onSurface)),
                    Text('${list.length} sessions', style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                loading: () => Text('History', style: AppTextStyles.h2().copyWith(color: scheme.onSurface)),
                error: (e, st) => Text('History', style: AppTextStyles.h2().copyWith(color: scheme.onSurface)),
              ),
            ),
            _FilterStrip(filters: filters),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: async.when(
                loading: () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 6,
                  separatorBuilder: (c, i) =>
                      const SizedBox(height: AppSpacing.cardListGap),
                  itemBuilder: (c, i) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load history', style: AppTextStyles.body()),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(
                          sessionSummariesProvider(
                            subject: filters.subject,
                            mode: filters.mode,
                          ),
                        ),
                        child: Text('Retry', style: AppTextStyles.label()),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filters.subject == null && filters.mode == null
                                ? 'No sessions yet'
                                : 'No sessions found',
                            style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            filters.subject == null && filters.mode == null
                                ? 'Complete a test to see your history here'
                                : 'Try changing your filters',
                            style: AppTextStyles.bodySm()
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: list.length,
                    separatorBuilder: (c, i) =>
                      const SizedBox(height: AppSpacing.cardListGap),
                    itemBuilder: (c, i) => _SessionCard(summary: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterStrip extends HookConsumerWidget {
  const _FilterStrip({required this.filters});
  final HistoryFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    Widget pill(String label, bool selected, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? AppColors.primary : border, width: 0.5),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSm().copyWith(
                color: selected ? AppColors.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        );

    return SizedBox(
      height: 42,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          pill('All', filters.subject == null && filters.mode == null, () => ref.read(historyFilterStateProvider.notifier).setAll()),
          const SizedBox(width: AppSpacing.sm),
          for (final s in SubjectConstants.ordered) ...[
            pill(s.displayName, filters.subject == s.slug, () => ref.read(historyFilterStateProvider.notifier).setSubject(s.slug)),
            const SizedBox(width: AppSpacing.sm),
          ],
          pill('Exam', filters.mode == 'exam', () => ref.read(historyFilterStateProvider.notifier).setMode('exam')),
          const SizedBox(width: AppSpacing.sm),
          pill('Learning', filters.mode == 'learning', () => ref.read(historyFilterStateProvider.notifier).setMode('learning')),
        ],
      ),
    );
  }
}

class _SessionCard extends HookConsumerWidget {
  const _SessionCard({required this.summary});
  final SessionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subj = SubjectConstants.bySlug(summary.subject)?.displayName ?? summary.subject;

    final modeBg = summary.status == 'abandoned'
        ? scheme.surfaceContainerLow
        : summary.status == 'in_progress'
            ? (isDark ? AppColors.warningBgDark : AppColors.warningBg)
            : summary.mode == 'exam'
                ? (isDark ? AppColors.infoBgDark : AppColors.infoBg)
                : (isDark ? AppColors.primaryDeep : AppColors.primaryLight);
    final modeFg = summary.status == 'abandoned'
        ? scheme.onSurfaceVariant
        : summary.status == 'in_progress'
            ? (isDark ? AppColors.warningTextDark : AppColors.warningText)
            : summary.mode == 'exam'
                ? (isDark ? AppColors.infoTextDark : AppColors.infoText)
                : (isDark ? AppColors.onPrimary : AppColors.primaryDeep);
    final modeLabel = summary.status == 'abandoned'
        ? 'Abandoned'
        : summary.status == 'in_progress'
            ? 'In progress'
            : (summary.mode == 'exam' ? 'Exam' : 'Learning');

    final accColor = switch (summary.accuracyTier) {
      'high' => AppColors.correct,
      'medium' => AppColors.warning,
      'low' => AppColors.wrong,
      _ => scheme.onSurfaceVariant,
    };

    final score = summary.correct == null ? '—' : '${summary.correct}/${summary.questionCount}';
    final avg = summary.avgTimeSpentSecs == null ? '—' : formatMmSsFromSecs(summary.avgTimeSpentSecs!.round());

    return Container(
      decoration: BoxDecoration(
        color: summary.status == 'abandoned'
            ? scheme.surfaceContainerLow
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Container(
        decoration: summary.status == 'in_progress'
            ? BoxDecoration(border: Border(left: BorderSide(color: AppColors.warning, width: 2)), borderRadius: BorderRadius.circular(AppRadius.lg))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subj,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label().copyWith(color: scheme.onSurface),
                        ),
                        if (summary.topic != null)
                          Text(
                            summary.topic!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm()
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(color: modeBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Text(modeLabel, style: AppTextStyles.caption().copyWith(color: modeFg)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(height: 0.5, color: border),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(summary.accuracy == null ? '—' : '${summary.accuracy!.toStringAsFixed(1)}%', style: AppTextStyles.labelSm().copyWith(color: accColor)),
                  Text(summary.status == 'in_progress' ? '$score done' : score, style: AppTextStyles.labelSm().copyWith(color: scheme.onSurface)),
                  Text(summary.netScore == null ? '—' : 'net ${summary.netScore!.toStringAsFixed(1)}', style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant)),
                  Text(avg, style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM, hh:mm a').format(summary.createdAt),
                      style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (summary.status == 'completed')
                    OutlinedButton(
                      onPressed: () =>
                          context.push('/history/${summary.sessionId}'),
                      child: Text('Review', style: AppTextStyles.labelSm()),
                    )
                  else if (summary.status == 'in_progress')
                    ElevatedButton(
                      onPressed: () =>
                          context.push('/test/${summary.sessionId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text('Resume', style: AppTextStyles.labelSm()),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => context.push(
                        summary.topic == null
                            ? '/subject-test'
                            : '/topic-test',
                      ),
                      child: Text('Restart', style: AppTextStyles.labelSm()),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
