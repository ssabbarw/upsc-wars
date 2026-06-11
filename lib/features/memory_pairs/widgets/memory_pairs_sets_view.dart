import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_scoring.dart';
import '../providers/memory_pairs_providers.dart';
import 'memory_pair_shared_widgets.dart';

class MemoryPairsSetsView extends ConsumerWidget {
  const MemoryPairsSetsView({super.key, required this.onOpenSet});

  final ValueChanged<MemoryPairSetDefinition> onOpenSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = watchAppLanguage(ref);
    final async = ref.watch(memoryPairSetListProvider);
    final scheme = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(memoryPairSetListProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (items) {
        final open = items.where((i) => i.isUnlocked).toList();
        final locked = items.where((i) => !i.isUnlocked).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              'Match the pairs, lock in the recall. Finish fast — stars are earned on speed.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const MemoryPairSectionLabel(label: 'Ready to play'),
            ...open.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SetRow(
                  item: item,
                  lang: lang,
                  onTap: () => onOpenSet(item.definition),
                ),
              ),
            ),
            if (locked.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const MemoryPairSectionLabel(label: 'Locked'),
              ...locked.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _LockedRow(item: item, lang: lang),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.item,
    required this.lang,
    required this.onTap,
  });

  final MemoryPairSetListItem item;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final def = item.definition;
    final scheme = Theme.of(context).colorScheme;
    final played = item.bestSeconds != null;

    return MemoryPairSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          MemoryPairSubjectIcon(icon: def.icon, color: def.accentColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.nameForLang(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${def.subjectLabelForLang(lang)} · ${def.pairs.length} pairs',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (played) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      formatMemoryPairTime(item.bestSeconds!),
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  memoryPairRelativePlayed(item.lastPlayedAt),
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'New',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.item, required this.lang});

  final MemoryPairSetListItem item;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final def = item.definition;
    final scheme = Theme.of(context).colorScheme;
    final pct = item.unlockRequired == 0
        ? 100
        : ((item.unlockProgress / item.unlockRequired) * 100).round().clamp(0, 100);

    return MemoryPairSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.nameForLang(lang),
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Attempt ${def.unlockQuestionsRequired} ${def.subjectLabelForLang(lang)} questions',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.unlockRequired == 0 ? 1 : item.unlockProgress / item.unlockRequired,
              minHeight: 5,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.unlockProgress} / ${item.unlockRequired} done ($pct%)',
            style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
