import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/trap_pattern_catalog.dart';

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
    final countLabel = item.caughtCount == 0
        ? 'Caught you 0×'
        : 'Caught you ${item.caughtCount}×';

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
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
                children: [
                  Expanded(
                    child: Text(
                      item.displayName,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    countLabel,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (item.blurb.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.blurb,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onSeeExample,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                  ),
                  child: const Text('See example'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
