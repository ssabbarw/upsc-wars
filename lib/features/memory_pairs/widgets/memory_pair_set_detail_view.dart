import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_scoring.dart';
import '../providers/memory_pairs_providers.dart';
import 'memory_pair_shared_widgets.dart';

class MemoryPairSetDetailView extends HookConsumerWidget {
  const MemoryPairSetDetailView({
    super.key,
    required this.set,
    required this.lang,
    required this.onRevise,
    required this.onPlay,
  });

  final MemoryPairSetDefinition set;
  final String lang;
  final void Function(MemoryPairDifficulty difficulty) onRevise;
  final void Function(MemoryPairDifficulty difficulty) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final difficulty = useState(MemoryPairDifficulty.medium);
    final statsAsync = ref.watch(
      memoryPairSetStatsProvider((set.id, difficulty.value)),
    );
    final bestSeconds = statsAsync.maybeWhen(
      data: (s) => s?.bestSeconds,
      orElse: () => null,
    );
    final lastPlayed = statsAsync.maybeWhen(
      data: (s) => s?.lastPlayedAt,
      orElse: () => null,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            MemoryPairSubjectIcon(
              icon: set.icon,
              color: set.accentColor,
              size: 52,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.nameForLang(lang),
                    style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  ),
                  Text(
                    set.subjectLabelForLang(lang),
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        MemoryPairSurfaceCard(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(
                  value: '${set.pairs.length}',
                  label: 'Total pairs',
                ),
                _StatCell(
                  value: bestSeconds != null
                      ? formatMemoryPairTime(bestSeconds)
                      : '—',
                  label: 'Best time',
                  accent: true,
                ),
                _StatCell(
                  value: memoryPairRelativePlayed(lastPlayed),
                  label: 'Last played',
                  small: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const MemoryPairSectionLabel(label: 'Difficulty'),
        Row(
          children: MemoryPairDifficulty.values.map((d) {
            final active = d == difficulty.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: d != MemoryPairDifficulty.hard ? AppSpacing.sm : 0,
                ),
                child: OutlinedButton(
                  onPressed: () => difficulty.value = d,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    backgroundColor: active
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : scheme.surface,
                    side: BorderSide(
                      color: active ? AppColors.primary : scheme.outline,
                      width: active ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        d.label,
                        style: AppTextStyles.labelSm().copyWith(
                          color: active ? AppColors.primary : scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${d.pairCount} pairs',
                        style: AppTextStyles.caption().copyWith(
                          color: active
                              ? AppColors.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onRevise(difficulty.value),
                icon: const Icon(Icons.style_outlined, size: 18),
                label: const Text('Revise'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => onPlay(difficulty.value),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Play now'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.accent = false,
    this.small = false,
  });

  final String value;
  final String label;
  final bool accent;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (small ? AppTextStyles.labelSm() : AppTextStyles.h3())
                  .copyWith(
                color: accent ? AppColors.primary : scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
