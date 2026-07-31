import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/en_hi_language_toggle.dart';
import '../domain/memory_pair_catalog_grouping.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_subject_meta.dart';
import '../providers/memory_pairs_providers.dart';
import 'memory_pairs_catalog_widgets.dart';
import 'memory_pairs_help_sheet.dart';

class MemoryPairsSetsView extends ConsumerWidget {
  const MemoryPairsSetsView({
    super.key,
    required this.onOpenSubject,
  });

  final ValueChanged<MemoryPairSubjectGroup> onOpenSubject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = watchAppLanguage(ref);
    final async = ref.watch(memoryPairSetListProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(memoryPairSetListProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (items) {
        final groups = groupMemoryPairSetsBySubject(items, lang: lang);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Memory Pairs',
                        style: AppTextStyles.h2().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Learn. Recall. Master.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                EnHiLanguageToggle(
                  language: lang,
                  onChanged: (v) => persistAppLanguage(ref, v),
                  minHeight: 32,
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => showMemoryPairsHelpSheet(context),
                  icon: Icon(
                    Icons.help_outline_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
                        : scheme.surfaceContainerLowest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Browse by Subject',
              style: AppTextStyles.labelSm().copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < groups.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < groups.length - 1 ? AppSpacing.sm : 0,
                ),
                child: _SubjectCard(
                  group: groups[i],
                  onTap: () => onOpenSubject(groups[i]),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _HowItWorksCard(
              onTap: () => showMemoryPairsHelpSheet(context),
            ),
          ],
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.group, required this.onTap});

  final MemoryPairSubjectGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = memoryPairSubjectVisual(group.subjectKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: memoryPairCatalogCardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.accent.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.22
                        : 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.subjectLabel,
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.totalSets} topics',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              MemoryPairDifficultyCountStrip(
                easy: group.countForDifficulty(MemoryPairDifficulty.easy),
                medium: group.countForDifficulty(MemoryPairDifficulty.medium),
                hard: group.countForDifficulty(MemoryPairDifficulty.hard),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works?',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topics are grouped by difficulty. Earn stars as you '
                      'master harder topics!',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
