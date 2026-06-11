import 'package:flutter/material.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_catalog_grouping.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_scoring.dart';
import '../domain/memory_pair_subject_meta.dart';
import 'memory_pair_shared_widgets.dart';
import 'memory_pairs_catalog_widgets.dart';

class MemoryPairsSubjectView extends StatelessWidget {
  const MemoryPairsSubjectView({
    super.key,
    required this.group,
    required this.lang,
    required this.onOpenSet,
  });

  final MemoryPairSubjectGroup group;
  final String lang;
  final ValueChanged<MemoryPairSetDefinition> onOpenSet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = memoryPairSubjectVisual(group.subjectKey);
    final items = group.sortedItems;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          visual.subtitleForLang(lang),
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i < items.length - 1 ? AppSpacing.sm : 0,
            ),
            child: _TopicCard(
              item: items[i],
              lang: lang,
              onTap: items[i].isUnlocked
                  ? () => onOpenSet(items[i].definition)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.item,
    required this.lang,
    required this.onTap,
  });

  final MemoryPairSetListItem item;
  final String lang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final def = item.definition;
    final scheme = Theme.of(context).colorScheme;
    final unlocked = item.isUnlocked;
    final playCount = def.difficulty.pairCount.clamp(0, def.pairs.length);

    final tierStars = () {
      if (item.bestSeconds != null) {
        return starsForTime(item.bestSeconds!, playCount).clamp(1, 3);
      }
      return switch (def.difficulty) {
        MemoryPairDifficulty.easy => 1,
        MemoryPairDifficulty.medium => 2,
        MemoryPairDifficulty.hard => 3,
      };
    }();

    final pct = item.unlockRequired == 0
        ? 100
        : ((item.unlockProgress / item.unlockRequired) * 100)
            .round()
            .clamp(0, 100);
    final progress = item.unlockRequired == 0
        ? 1.0
        : (item.unlockProgress / item.unlockRequired).clamp(0.0, 1.0);
    final unlockSubjectLabel =
        SubjectConstants.bySlug(def.unlockSubjectSlug)?.displayName ??
            def.unlockSubjectSlug;

    return Opacity(
      opacity: unlocked ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: memoryPairCatalogCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MemoryPairSubjectIcon(
                      icon: def.icon,
                      color: def.accentColor,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            def.nameForLang(lang),
                            style: AppTextStyles.label().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (unlocked) ...[
                            const SizedBox(height: 4),
                            Text(
                              memoryPairSetBlurb(def, lang),
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          MemoryPairDifficultyChip(difficulty: def.difficulty),
                        ],
                      ),
                    ),
                    Icon(
                      unlocked ? Icons.chevron_right_rounded : Icons.lock_outline,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                if (!unlocked) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'To unlock, attempt ${item.unlockRequired} '
                    '$unlockSubjectLabel questions',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: AppColors.primary.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$pct%',
                        style: AppTextStyles.labelSm().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.unlockProgress} of ${item.unlockRequired} done',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (unlocked) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.bestSeconds != null) ...[
                        Text(
                          formatMemoryPairTime(item.bestSeconds!),
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      MemoryPairTierStars(filled: tierStars),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
