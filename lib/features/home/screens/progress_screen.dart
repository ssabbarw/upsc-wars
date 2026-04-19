import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/shimmer_box.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../subject_detail/domain/subject_insights.dart';
import '../../subject_detail/domain/subject_overview_row.dart';
import '../../subject_detail/providers/all_subjects_overview_provider.dart';

class ProgressScreen extends HookConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(allSubjectsOverviewProvider);
    final sortMode = useState(SubjectSortMode.mistakes);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return PopToShellHomeScope(
      child: Scaffold(
        body: SafeArea(
          child: overviewAsync.when(
          loading: () => _ProgressSkeleton(borderColor: borderColor),
          error: (e, _) => Center(
            child: Text(
              'Could not load overview.',
              style: AppTextStyles.bodySm().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          data: (rows) {
            final sorted = _sortedRows(rows, sortMode.value);
            final totalWrong = rows.fold(
              0,
              (sum, r) => sum + r.wrongCountLast30Days,
            );
            final attemptedCount = rows.where((r) => r.hasAttempts).length;

            return CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Header(
                    totalWrong: totalWrong,
                    attemptedCount: attemptedCount,
                    borderColor: borderColor,
                  ),
                ),
                // ── Sort chips ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SortChips(
                    sortMode: sortMode.value,
                    onSortChanged: (m) => sortMode.value = m,
                  ),
                ),
                // ── Subject rows ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardListGap),
                    itemBuilder: (context, i) => _SubjectRow(
                      row: sorted[i],
                      borderColor: borderColor,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    child: const Center(child: ContactUsTextButton()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
    );
  }

  List<SubjectOverviewRow> _sortedRows(
    List<SubjectOverviewRow> rows,
    SubjectSortMode mode,
  ) {
    final copy = List<SubjectOverviewRow>.from(rows);
    switch (mode) {
      case SubjectSortMode.mistakes:
        // Worst (most wrong) first; not-started at end.
        copy.sort((a, b) {
          if (!a.hasAttempts && !b.hasAttempts) return 0;
          if (!a.hasAttempts) return 1;
          if (!b.hasAttempts) return -1;
          final byCounts = b.wrongCountLast30Days.compareTo(a.wrongCountLast30Days);
          if (byCounts != 0) return byCounts;
          return b.totalAttempted.compareTo(a.totalAttempted);
        });
      case SubjectSortMode.accuracy:
        // Lowest accuracy first; not-started at end.
        copy.sort((a, b) {
          if (!a.hasAttempts && !b.hasAttempts) return 0;
          if (!a.hasAttempts) return 1;
          if (!b.hasAttempts) return -1;
          return (a.accuracyPercent ?? 0).compareTo(b.accuracyPercent ?? 0);
        });
      case SubjectSortMode.alphabetical:
        copy.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
    return copy;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Header
// ────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.totalWrong,
    required this.attemptedCount,
    required this.borderColor,
  });

  final int totalWrong;
  final int attemptedCount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress', style: AppTextStyles.h2()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your performance across all subjects',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Summary strip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: isDark ? AppColors.wrongTextDark : AppColors.wrongText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySm().copyWith(
                        color: isDark
                            ? AppColors.wrongTextDark
                            : AppColors.wrongText,
                      ),
                      children: [
                        TextSpan(
                          text: '$totalWrong ',
                          style: AppTextStyles.bodyMd().copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.wrongTextDark
                                : AppColors.wrongText,
                          ),
                        ),
                        TextSpan(
                          text: totalWrong == 1
                              ? 'mistake this month · '
                              : 'mistakes this month · ',
                        ),
                        TextSpan(
                          text: '$attemptedCount/8',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' subjects practised'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sort chips
// ────────────────────────────────────────────────────────────────────────────

class _SortChips extends StatelessWidget {
  const _SortChips({
    required this.sortMode,
    required this.onSortChanged,
  });

  final SubjectSortMode sortMode;
  final ValueChanged<SubjectSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String label, SubjectSortMode mode) {
      final selected = sortMode == mode;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSortChanged(mode),
        labelStyle: AppTextStyles.bodySm().copyWith(
          color: selected ? AppColors.onPrimary : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: scheme.surfaceContainerLow,
        showCheckmark: false,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          chip('Most mistakes', SubjectSortMode.mistakes),
          const SizedBox(width: AppSpacing.sm),
          chip('Accuracy ↑', SubjectSortMode.accuracy),
          const SizedBox(width: AppSpacing.sm),
          chip('A – Z', SubjectSortMode.alphabetical),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Subject row
// ────────────────────────────────────────────────────────────────────────────

class _SubjectRow extends ConsumerWidget {
  const _SubjectRow({required this.row, required this.borderColor});

  final SubjectOverviewRow row;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accuracy = row.accuracyPercent;
    final accuracyText =
        accuracy != null ? '${accuracy.toStringAsFixed(0)}%' : null;

    return GestureDetector(
      onTap: () => context.push(
        '/subject/${Uri.encodeComponent(row.subject)}',
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // ── Subject icon ────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: isDark ? 0.12 : 1.0),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                row.icon,
                size: 22,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // ── Subject name + stats ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.displayName,
                    style: AppTextStyles.bodyMd().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (row.hasAttempts)
                    Text(
                      '${row.totalAttempted} attempted · ${accuracyText ?? '—'} accuracy',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Text(
                      'Not started',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // ── Right: mistake count + risk badge ───────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (row.hasAttempts) ...[
                  _RiskBadge(row: row, isDark: isDark),
                  const SizedBox(height: 4),
                  Text(
                    '${row.wrongCountLast30Days} this month',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ] else
                  _NotStartedBadge(isDark: isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.row, required this.isDark});

  final SubjectOverviewRow row;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (row.riskTier) {
      case RiskTier.high:
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        fg = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
      case RiskTier.medium:
        bg = isDark ? AppColors.warningBgDark : AppColors.warningBg;
        fg = isDark ? AppColors.warningTextDark : AppColors.warningText;
      case RiskTier.low:
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${row.riskTier.emoji} ${row.riskTier.label}',
        style: AppTextStyles.bodySm().copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _NotStartedBadge extends StatelessWidget {
  const _NotStartedBadge({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceTertiaryDark
            : AppColors.surfaceTertiaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Not started',
        style: AppTextStyles.bodySm().copyWith(
          color: isDark ? AppColors.gray400 : AppColors.gray600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Skeleton
// ────────────────────────────────────────────────────────────────────────────

class _ProgressSkeleton extends HookWidget {
  const _ProgressSkeleton({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget row() => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: AppRadius.md),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 13),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShimmerBox(width: 64, height: 22, borderRadius: AppRadius.pill),
            ],
          ),
        );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 100, height: 22),
          const SizedBox(height: AppSpacing.xs),
          ShimmerBox(width: 200, height: 13),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(width: double.infinity, height: 52, borderRadius: AppRadius.md),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
            8,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.cardListGap),
              child: row(),
            ),
          ),
        ],
      ),
    );
  }
}
