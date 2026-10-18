import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';

/// Rounded catalog card surface — works in light and dark mode.
BoxDecoration memoryPairCatalogCardDecoration(
  BuildContext context, {
  bool elevated = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    color: isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
        : scheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(
      color: isDark
          ? AppColors.borderDark.withValues(alpha: 0.8)
          : AppColors.borderLight,
      width: 0.5,
    ),
    boxShadow: elevated && !isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : null,
  );
}

class MemoryPairDifficultyTabBar extends StatelessWidget {
  const MemoryPairDifficultyTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MemoryPairDifficulty selected;
  final ValueChanged<MemoryPairDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Row(
        children: MemoryPairDifficulty.values.map((d) {
          final active = d == selected;
          final color = d.chipColor(context);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: d != MemoryPairDifficulty.hard ? 4 : 0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(d),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? (isDark
                                ? color.withValues(alpha: 0.22)
                                : color.withValues(alpha: 0.14))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      d.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm().copyWith(
                        color: active ? color : scheme.onSurfaceVariant,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Up to 3 stars — filled count indicates tier or mastery preview.
class MemoryPairTierStars extends StatelessWidget {
  const MemoryPairTierStars({super.key, required this.filled, this.size = 16});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyColor = isDark ? AppColors.gray600 : AppColors.borderLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < filled.clamp(0, 3);
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 2 : 0),
          child: Icon(
            on ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: on ? AppColors.warning : emptyColor,
          ),
        );
      }),
    );
  }
}

class MemoryPairDifficultyCountStrip extends StatelessWidget {
  const MemoryPairDifficultyCountStrip({
    super.key,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  final int easy;
  final int medium;
  final int hard;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CountCell(
          label: 'Easy',
          count: easy,
          color: MemoryPairDifficulty.easy.chipColor(context),
        ),
        const SizedBox(width: 10),
        _CountCell(
          label: 'Medium',
          count: medium,
          color: MemoryPairDifficulty.medium.chipColor(context),
        ),
        const SizedBox(width: 10),
        _CountCell(
          label: 'Hard',
          count: hard,
          color: MemoryPairDifficulty.hard.chipColor(context),
        ),
      ],
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: AppTextStyles.labelSm().copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
