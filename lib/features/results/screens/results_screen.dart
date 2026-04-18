import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/revision_queue_item.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/prelims_countdown_card.dart';
import '../../../shared/extensions/time_formatting.dart';
import '../../battle/widgets/battle_live_scoreboard.dart';
import '../widgets/confidence_insights_section.dart';

class ResultsScreen extends HookConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionResultProvider(sessionId));
    final revisionAsync = ref.watch(revisionQueueItemsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e is SessionNotFoundException
                        ? 'Session not found'
                        : 'Could not load results',
                    style: AppTextStyles.body(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (e is! SessionNotFoundException)
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(sessionResultProvider(sessionId)),
                      child: Text('Retry', style: AppTextStyles.label()),
                    ),
                  if (e is SessionNotFoundException) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go('/'),
                      child: Text('Home', style: AppTextStyles.label()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          data: (r) {
            final subj =
                SubjectConstants.bySlug(r.subject)?.displayName ?? r.subject;
            final totalSpent = r.totalTimeSpentSecs;
            final totalAllowed = r.timeLimitSecs;
            final accColor = _accuracyColor(
              r.accuracyTier,
              scheme.onSurfaceVariant,
              r.accuracy,
            );
            final netColor = r.netScore < 0
                ? AppColors.wrong
                : scheme.onSurfaceVariant;
            final unattemptedForDisplay = r.unattempted + r.timedOut;

            return Column(
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
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Results',
                        style: AppTextStyles.h2().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      BattleLiveScoreboard(sessionId: sessionId),
                      const SizedBox(height: AppSpacing.md),
                      if (r.dangerZoneWrongCount > 0) ...[
                        _DangerZoneHeroCard(
                          sessionId: sessionId,
                          result: r,
                          scheme: scheme,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (ConfidenceInsightsSection.shouldShow(r)) ...[
                        ConfidenceInsightsSection(
                          sessionId: sessionId,
                          result: r,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subj,
                              style: AppTextStyles.h1().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            if (r.topic != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Text(
                                  r.topic!,
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            _ModeBadge(mode: r.mode),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(r.completedAt ?? r.createdAt),
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const PrelimsCountdownCard(),
                      const SizedBox(height: AppSpacing.md),
                      _Card(
                        child: Column(
                          children: [
                            Text(
                              '${r.correct} / ${r.questionCount}',
                              style: AppTextStyles.h1().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${r.accuracy.toStringAsFixed(1)}%',
                              style: AppTextStyles.h2().copyWith(
                                color: accColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Net score: ${r.netScore.toStringAsFixed(1)}',
                              style: AppTextStyles.bodySm().copyWith(
                                color: netColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.6,
                        children: [
                          _StatTile(
                            label: 'Correct',
                            value: '${r.correct}',
                            color: AppColors.correct,
                          ),
                          _StatTile(
                            label: 'Wrong',
                            value: '${r.wrong}',
                            color: AppColors.wrong,
                          ),
                          _StatTile(
                            label: 'Unattempted',
                            value: '$unattemptedForDisplay',
                            color: scheme.onSurfaceVariant,
                          ),
                          _StatTile(
                            label: 'Avg time',
                            value: r.avgTimeSpentSecs == null
                                ? '—'
                                : formatMmSsFromSecs(
                                    r.avgTimeSpentSecs!.round(),
                                  ),
                            color: scheme.onSurface,
                          ),
                        ],
                      ),
                      if (totalAllowed != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completed in ${formatMmSsFromSecs(totalSpent)} of ${formatMmSsFromSecs(totalAllowed)}',
                                style: AppTextStyles.bodySm().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              LinearProgressIndicator(
                                value: totalAllowed == 0
                                    ? 0
                                    : (totalSpent / totalAllowed).clamp(0, 1),
                                color: AppColors.primary,
                                backgroundColor: scheme.surfaceContainerLow,
                              ),
                            ],
                          ),
                        ),
                      ],
                      ..._buildWeakAreasCallout(
                        revisionAsync,
                        r.createdAt,
                        scheme,
                      ),
                      ..._buildGraduatedCallout(r, scheme),
                      const SizedBox(height: AppSpacing.md),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Breakdown',
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _BreakdownBar(
                              correct: r.correct,
                              wrong: r.wrong,
                              unattempted: unattemptedForDisplay,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton(
                        onPressed: () =>
                            context.push('/history/${r.sessionId}'),
                        child: Text(
                          'Review answers',
                          style: AppTextStyles.label(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: () => context.go('/'),
                        child: Text('Go home', style: AppTextStyles.label()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Widget> _buildGraduatedCallout(SessionResult r, ColorScheme scheme) {
  if (r.subject != 'revision_quick' || r.graduatedCount == 0) return [];
  final n = r.graduatedCount;
  final isDark = scheme.brightness == Brightness.dark;
  final bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
  final fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
  return [
    const SizedBox(height: AppSpacing.md),
    Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.correct, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$n ${n == 1 ? 'question' : 'questions'} cleared from your revision list',
              style: AppTextStyles.bodySm().copyWith(color: fg),
            ),
          ),
        ],
      ),
    ),
  ];
}

List<Widget> _buildWeakAreasCallout(
  AsyncValue<List<RevisionQueueItem>> revisionAsync,
  DateTime sessionCreatedAt,
  ColorScheme scheme,
) {
  return revisionAsync.when(
    loading: () => [],
    error: (e, st) => [],
    data: (items) {
      final newItems = items
          .where((i) => !i.dateAddedToQueue.isBefore(sessionCreatedAt))
          .toList();
      if (newItems.isEmpty) return [];

      final concepts = newItems.map((i) => i.conceptAnchor).toSet().toList();
      final traps = newItems
          .map((i) => i.trapType)
          .whereType<String>()
          .toSet()
          .toList();

      final totalNew = concepts.length + traps.length;
      final parts = [
        ...concepts.take(2),
        ...traps
            .take(2)
            .map(
              (t) => t
                  .split('-')
                  .map(
                    (w) => w.isEmpty
                        ? w
                        : '${w[0].toUpperCase()}${w.substring(1)}',
                  )
                  .join(' '),
            ),
      ];

      return [
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalNew new weak ${totalNew == 1 ? 'area' : 'areas'} identified',
                style: AppTextStyles.label().copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
              if (parts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  parts.join(' · '),
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onErrorContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ];
    },
  );
}

Color _accuracyColor(String tier, Color fallback, double accuracy) {
  if (accuracy == 0) return AppColors.wrong;
  switch (tier) {
    case 'high':
      return AppColors.correct;
    case 'medium':
      return AppColors.warning;
    case 'low':
      return AppColors.wrong;
    default:
      return fallback;
  }
}

class _Card extends HookConsumerWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _DangerZoneHeroCard extends StatelessWidget {
  const _DangerZoneHeroCard({
    required this.sessionId,
    required this.result,
    required this.scheme,
  });

  final String sessionId;
  final SessionResult result;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.wrong, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Biggest Mistake",
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'You were confidently wrong on ${result.dangerZoneWrongCount} question${result.dangerZoneWrongCount == 1 ? '' : 's'}',
                      style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This would cost ${result.dangerZoneMarksEstimate.toStringAsFixed(2)} marks in UPSC Prelims',
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/danger-zone/$sessionId'),
              child: Text(
                'Review Danger Zone Questions',
                style: AppTextStyles.label().copyWith(color: scheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends HookConsumerWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.h3().copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ModeBadge extends HookConsumerWidget {
  const _ModeBadge({required this.mode});
  final String mode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exam = mode == 'exam';
    final bg = exam
        ? (isDark ? AppColors.infoBgDark : AppColors.infoBg)
        : (isDark ? AppColors.primaryDeep : AppColors.primaryLight);
    final fg = exam
        ? (isDark ? AppColors.infoTextDark : AppColors.infoText)
        : (isDark ? AppColors.onPrimary : AppColors.primaryDeep);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        exam ? 'Exam' : 'Learning',
        style: AppTextStyles.caption().copyWith(color: fg),
      ),
    );
  }
}

class _BreakdownBar extends HookConsumerWidget {
  const _BreakdownBar({
    required this.correct,
    required this.wrong,
    required this.unattempted,
  });
  final int correct;
  final int wrong;
  final int unattempted;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = (correct + wrong + unattempted).toDouble();
    final c = total == 0 ? 0.0 : correct / total;
    final w = total == 0 ? 0.0 : wrong / total;
    final u = total == 0 ? 1.0 : unattempted / total;
    return Row(
      children: [
        Expanded(
          flex: (c * 1000).round().clamp(1, 1000),
          child: Container(height: 14, color: AppColors.correct),
        ),
        Expanded(
          flex: (w * 1000).round().clamp(1, 1000),
          child: Container(height: 14, color: AppColors.wrong),
        ),
        Expanded(
          flex: (u * 1000).round().clamp(1, 1000),
          child: Container(
            height: 14,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
        ),
      ],
    );
  }
}
