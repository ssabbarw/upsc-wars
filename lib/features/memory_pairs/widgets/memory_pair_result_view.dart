import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_scoring.dart';
import 'memory_pair_shared_widgets.dart';

class MemoryPairResultView extends StatelessWidget {
  const MemoryPairResultView({
    super.key,
    required this.set,
    required this.difficulty,
    required this.lang,
    required this.result,
    required this.isNewBest,
    required this.onTryAnotherSet,
    required this.onPlayAgain,
    required this.onExit,
  });

  final MemoryPairSetDefinition set;
  final MemoryPairDifficulty difficulty;
  final String lang;
  final MemoryPairGameResult result;
  final bool isNewBest;
  final VoidCallback onTryAnotherSet;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stars = starsForResult(result);
    final weak = result.weakPairs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          set.nameForLang(lang),
          textAlign: TextAlign.center,
          style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Complete',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(child: MemoryPairStars(value: stars, size: 30, gap: 6)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$stars / 5 · ${starVerdict(stars)}',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatBlock(
              icon: Icons.timer_outlined,
              value: formatMemoryPairTime(result.seconds),
              label: 'Time',
              color: AppColors.primary,
            ),
            Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              color: scheme.outlineVariant,
            ),
            _StatBlock(
              icon: Icons.error_outline,
              value: '${result.errors}',
              label: 'Errors',
              color: result.errors > 0 ? AppColors.wrong : scheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        MemoryPairSurfaceCard(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                _MiniStat(
                  value: formatMemoryPairTime(result.seconds),
                  label: 'Total time',
                ),
                _MiniStat(
                  value: '${result.errors}',
                  label: 'Total errors',
                ),
                _MiniStat(
                  value: '${result.pairsCount}',
                  label: 'Pairs cleared',
                ),
              ],
            ),
          ),
        ),
        if (isNewBest) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'New best time for this set',
                    style: AppTextStyles.labelSm().copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (weak.isNotEmpty)
          _WeakList(pairs: weak, lang: lang)
        else
          MemoryPairSurfaceCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'No wrong taps — full recall',
                  style: AppTextStyles.labelSm().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xxxl),
        OutlinedButton.icon(
          onPressed: onTryAnotherSet,
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('Try another set'),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: onPlayAgain,
          icon: const Icon(Icons.refresh),
          label: const Text('Play again'),
        ),
        TextButton(
          onPressed: onExit,
          child: const Text('Back to sets'),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.h2().copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1,
              ),
            ),
          ],
        ),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption().copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.label().copyWith(fontWeight: FontWeight.w700),
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

class _WeakList extends StatelessWidget {
  const _WeakList({required this.pairs, required this.lang});

  final List<MemoryPair> pairs;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.replay, size: 18, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              '${pairs.length} pair${pairs.length > 1 ? 's' : ''} you got wrong',
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        MemoryPairSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < pairs.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pairs[i].termForLang(lang),
                          style: AppTextStyles.labelSm().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: scheme.onSurfaceVariant),
                      Expanded(
                        child: Text(
                          pairs[i].answerForLang(lang),
                          textAlign: TextAlign.right,
                          style: AppTextStyles.labelSm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
