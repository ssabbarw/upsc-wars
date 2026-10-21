import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/series_stats.dart';
import '../../domain/test_series_models.dart';
import '../../providers/test_series_providers.dart';
import '../series_get_help_card.dart';
import '../series_paywall_sheet.dart';
import 'series_insight_example_sheet.dart';
import 'series_intro_sections.dart';
import 'series_sample_question_sheet.dart';
import '../../../../l10n/l10n.dart';

/// Overview tab for people who have not unlocked the series: the sales page.
///
/// Shows what is in the series, lets them start free PYQ tests and see a real
/// explanation. The other tabs sit right above for anyone who wants to look at
/// every test; [SeriesUnlockBar] keeps the buy button in reach.
class SeriesIntroTab extends ConsumerWidget {
  const SeriesIntroTab({
    super.key,
    required this.bundle,
    required this.isHindi,
    required this.stats,
    required this.tabController,
  });

  final SeriesBundle bundle;
  final bool isHindi;
  final SeriesStats stats;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> unlock() async {
      await showSeriesPaywall(context: context, bundle: bundle);
    }

    Future<void> openSampleQuestion() async {
      final wantsUnlock = await showSeriesSampleQuestionSheet(context);
      if (wantsUnlock && context.mounted) await unlock();
    }

    Future<void> openAnalysisExample() async {
      final wantsUnlock = await showSeriesInsightExampleSheet(context);
      if (wantsUnlock && context.mounted) await unlock();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(seriesBundleProvider(bundle.info.id));
        refreshSeriesLocalState(ref, bundle.info.id);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          IntroHero(bundle: bundle, isHindi: isHindi),
          const SizedBox(height: AppSpacing.lg),
          IntroCounts(bundle: bundle),
          const SizedBox(height: AppSpacing.xxl),
          IntroFreePyq(
            bundle: bundle,
            stats: stats,
            onSeeAll: () => tabController.animateTo(SeriesBrowseTab.pyqAndCa),
          ),
          const SizedBox(height: AppSpacing.xxl),
          IntroExplanations(
            onSeeExample: () => unawaited(openSampleQuestion()),
          ),
          const SizedBox(height: AppSpacing.xxl),
          IntroSmartTools(
            onSeeAnalysisExample: () => unawaited(openAnalysisExample()),
          ),
          const SizedBox(height: AppSpacing.xxl),
          IntroExamRealism(bundle: bundle),
          const SizedBox(height: AppSpacing.xxl),
          IntroWrapUp(
            bundle: bundle,
            onTryFree: () => tabController.animateTo(SeriesBrowseTab.pyqAndCa),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SeriesGetHelpCard(),
        ],
      ),
    );
  }
}

/// Always-visible buy bar: price on the left, button on the right. Hidden when
/// the series is not on sale.
class SeriesUnlockBar extends ConsumerWidget {
  const SeriesUnlockBar({super.key, required this.bundle});

  final SeriesBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSell = ref.watch(testSeriesCanSellProvider).asData?.value ?? false;
    if (!canSell) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = ref
        .watch(seriesProductProvider(bundle.info.productId))
        .asData
        ?.value
        ?.priceString;

    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: AppColors.gray900.withValues(alpha: isDark ? 0.8 : 0.25),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (price != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price,
                        style: AppTextStyles.h1().copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.l10n.tsOneTimeNoSub,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => unawaited(
                    showSeriesPaywall(context: context, bundle: bundle),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(context.l10n.tsUnlockAll),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
