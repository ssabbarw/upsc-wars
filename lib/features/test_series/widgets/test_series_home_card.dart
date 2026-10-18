import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/test_series_providers.dart';

/// Standalone Home section for the Prelims Test Series.
///
/// Renders nothing unless [testSeriesEntryVisibleProvider] allows it (sales on,
/// the user owns a series, or a superuser), so it disappears for non-buyers when
/// the Remote Config sales switch is off.
class TestSeriesHomeCard extends ConsumerWidget {
  const TestSeriesHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        ref.watch(testSeriesEntryVisibleProvider).asData?.value ?? false;
    if (!visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = ref.watch(appLanguageProvider).asData?.value == 'hi';

    final seriesId = ref.watch(activeSeriesIdProvider).asData?.value;
    final ownedIds =
        ref.watch(ownedSeriesIdsProvider).asData?.value ?? const {};
    final owned = seriesId != null && ownedIds.contains(seriesId);

    final bundle = seriesId == null
        ? null
        : ref.watch(seriesBundleProvider(seriesId)).asData?.value;
    final stats = (seriesId == null || !owned)
        ? null
        : ref.watch(seriesStatsProvider(seriesId)).asData?.value;

    final title =
        bundle?.info.displayTitle(hindi: isHindi) ?? 'Prelims Test Series';

    final String subtitle;
    if (owned && stats != null) {
      subtitle =
          '${stats.overall.attempted} of ${stats.overall.total} tests attempted';
    } else if (bundle != null) {
      final free = bundle.tests.where((t) => t.isFree).length;
      subtitle = owned
          ? '${bundle.tests.length} tests: subjects, current affairs and mocks'
          : '$free free tests to try. Subject tests, current affairs, full mocks.';
    } else {
      subtitle = 'Subject tests, current affairs and full-length mocks.';
    }

    final fraction = (owned && stats != null) ? stats.overall.fraction : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push('/test-series'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.warning.withValues(
                  alpha: isDark ? 0.55 : 0.45,
                ),
                width: 1,
              ),
              color: AppColors.warning.withValues(alpha: isDark ? 0.10 : 0.06),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h3(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fraction != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            color: AppColors.warning,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
