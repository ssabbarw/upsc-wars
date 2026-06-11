import 'package:flutter/material.dart';

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                visual.subtitleForLang(lang),
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MemoryPairSubjectIcon(
              icon: visual.icon,
              color: visual.accent,
              size: 44,
            ),
          ],
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
                          const SizedBox(height: 4),
                          Text(
                            memoryPairSetBlurb(def, lang),
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
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
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.unlockRequired == 0
                          ? 1
                          : item.unlockProgress / item.unlockRequired,
                      minHeight: 3,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.unlockProgress}/${item.unlockRequired} questions · $pct%',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (unlocked && item.bestSeconds != null) ...[
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
            ),
          ),
        ),
      ),
    );
  }
}
