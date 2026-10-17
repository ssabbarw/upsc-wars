import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/test_series_providers.dart';

/// Every test series the user bought (or tried), across years. A bought series
/// stays here after its Prelims is over: all tests remain attemptable and past
/// attempts keep their scores.
class MyTestSeriesScreen extends ConsumerWidget {
  const MyTestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(mySeriesIdsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Test Series')),
      body: idsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text("Couldn't load your test series.")),
        data: (ids) {
          if (ids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'You have not started a test series yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [for (final id in ids) _SeriesCard(seriesId: id)],
          );
        },
      ),
    );
  }
}

class _SeriesCard extends ConsumerWidget {
  const _SeriesCard({required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = ref.watch(appLanguageProvider).asData?.value == 'hi';
    final bundleAsync = ref.watch(seriesBundleProvider(seriesId));
    final statsAsync = ref.watch(seriesStatsProvider(seriesId));
    final owned =
        ref.watch(ownedSeriesIdsProvider).asData?.value.contains(seriesId) ?? false;

    final bundle = bundleAsync.asData?.value;
    final stats = statsAsync.asData?.value;
    final title = bundle?.info.displayTitle(hindi: isHindi) ?? seriesId;

    final prelims = bundle?.info.prelimsDate;
    final over = prelims != null && prelims.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push('/test-series/$seriesId'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(title, style: AppTextStyles.h3())),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: owned ? AppColors.primaryLight : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        owned ? 'Unlocked' : 'Free tests',
                        style: AppTextStyles.labelSm().copyWith(
                          color: owned ? AppColors.primaryDeep : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (stats != null)
                  Text(
                    '${stats.overall.attempted} of ${stats.overall.total} tests attempted'
                    '${stats.hasAnyAttempt ? ' · ${(stats.overallAccuracy * 100).round()}% accuracy' : ''}',
                    style: AppTextStyles.bodyMd(),
                  )
                else
                  Text('Loading…', style: AppTextStyles.bodyMd()),
                if (over) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Prelims is over. All tests stay open for practice.',
                    style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                if (bundle == null && bundleAsync.hasError) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Couldn't load this series.",
                    style: AppTextStyles.bodySm().copyWith(color: AppColors.wrong),
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
