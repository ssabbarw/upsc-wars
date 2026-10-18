import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/trap_pattern_catalog.dart';
import 'trap_pattern_visual.dart';
import '../../../l10n/l10n.dart';

class TrapPatternCard extends StatelessWidget {
  const TrapPatternCard({
    super.key,
    required this.item,
    required this.border,
    required this.onOpen,
    required this.onSeeExample,
  });

  final TrapPatternListItem item;
  final Color border;
  final VoidCallback onOpen;
  final VoidCallback onSeeExample;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = TrapPatternVisual.of(item.trapType);
    final caught = item.caughtCount > 0;
    final fill = Color.lerp(
      scheme.surface,
      visual.accent,
      caught ? (isDark ? 0.10 : 0.05) : 0,
    )!;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrapPatternIconWell(trapType: item.trapType),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.blurb.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.blurb,
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CaughtCountChip(count: item.caughtCount),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onSeeExample,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                  ),
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                  label: Text(context.l10n.trapsSeeExample),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaughtCountChip extends StatelessWidget {
  const _CaughtCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caught = count > 0;
    final bg = caught
        ? (isDark ? AppColors.warningBgDark : AppColors.warningBg)
        : scheme.surfaceContainerLow;
    final fg = caught
        ? (isDark ? AppColors.warningTextDark : AppColors.warningText)
        : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        caught ? context.l10n.trapsCaughtCount(count) : '0×',
        style: AppTextStyles.caption().copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
