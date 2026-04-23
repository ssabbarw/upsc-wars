import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/performance/mentor_performance_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../providers/performance_providers.dart';

class PerformanceOverviewScreen extends ConsumerWidget {
  const PerformanceOverviewScreen({super.key});

  static String _bandLabel(ReadinessBand b) {
    switch (b) {
      case ReadinessBand.critical:
        return 'Critical';
      case ReadinessBand.needsWork:
        return 'Needs work';
      case ReadinessBand.improving:
        return 'Improving';
      case ReadinessBand.strong:
        return 'Strong';
      case ReadinessBand.examReady:
        return 'Exam ready';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(performanceHomeBundleProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return PopToShellHomeScope(
      child: Scaffold(
        body: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load performance.',
                      style: AppTextStyles.body(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(performanceHomeBundleProvider),
                      child: Text('Retry', style: AppTextStyles.label()),
                    ),
                  ],
                ),
              ),
            ),
            data: (bundle) {
              final v = bundle.view;
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(performanceHomeBundleProvider);
                  await ref.read(performanceHomeBundleProvider.future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Performance',
                                style: AppTextStyles.h2().copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/legacy-progress'),
                              child: Text(
                                'Subject list',
                                style: AppTextStyles.caption(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _HeroReadiness(
                          readiness: v.readiness,
                          bandLabel: _bandLabel,
                          borderColor: borderColor,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          'Quick snapshot',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _SnapshotGrid(
                          quick: v.quick,
                          borderColor: borderColor,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: _FocusSection(
                          topics: v.focusRevisionTopics,
                          borderColor: borderColor,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          'By subject',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverList.separated(
                        itemCount: v.subjectCards.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.cardListGap),
                        itemBuilder: (context, i) {
                          final c = v.subjectCards[i];
                          return _SubjectCard(
                            card: c,
                            borderColor: borderColor,
                            onAnalysis: () => context.push(
                              '/performance/subject/${Uri.encodeComponent(c.subject)}',
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
                        child: Center(child: ContactUsTextButton()),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroReadiness extends StatelessWidget {
  const _HeroReadiness({
    required this.readiness,
    required this.bandLabel,
    required this.borderColor,
  });

  final ReadinessSnapshot readiness;
  final String Function(ReadinessBand) bandLabel;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPSC readiness',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${readiness.score}',
                style: AppTextStyles.h1().copyWith(
                  color: scheme.onSurface,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / 100',
                style: AppTextStyles.h2().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  bandLabel(readiness.band),
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          if (readiness.scoreChangeReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Why score changed',
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...readiness.scoreChangeReasons
                .take(4)
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      line,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.quick, required this.borderColor});

  final QuickSnapshot quick;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget cell(String title, String value) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      );
    }

    final edu = quick.smartGuessAttempted == 0
        ? '—'
        : '${quick.smartGuessAccuracyPercent.toStringAsFixed(0)}%';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: cell(
                'Accuracy',
                '${quick.overallAccuracyPercent.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: cell(
                'Dangerous mistakes',
                '${quick.dangerousMistakesCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: cell('Smart guess acc.', edu)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: cell('Revision pending', '${quick.revisionPendingCount}'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: cell('Strongest subject', quick.strongestSubject ?? '—'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: cell('Weakest subject', quick.weakestSubject ?? '—'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusSection extends StatelessWidget {
  const _FocusSection({required this.topics, required this.borderColor});

  final List<RevisionTopicRow> topics;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subjects = <String>{};
    for (final t in topics.take(4)) {
      subjects.add(t.subject);
    }
    final immediate = topics.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus this week',
            style: AppTextStyles.h2().copyWith(
              color: scheme.onSurface,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Revise first',
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subjects.isEmpty ? '—' : subjects.join(' · '),
            style: AppTextStyles.body().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Immediate priority',
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (immediate.isEmpty)
            Text(
              'Attempt more questions — we will rank topics automatically.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ...immediate.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '• ${r.topic} (${r.subject})',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'What to do next: open a subject below, then start with the top “revise” topic.',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.card,
    required this.borderColor,
    required this.onAnalysis,
  });

  final SubjectMentorCard card;
  final Color borderColor;
  final VoidCallback onAnalysis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${card.subject} — ${card.statusLine}',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${card.healthScore}/100',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              card.oneLineInsight,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onAnalysis,
                child: Text('View analysis', style: AppTextStyles.label()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
