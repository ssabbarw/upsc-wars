import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/series_stats.dart';
import '../providers/test_series_providers.dart';
import '../widgets/series_tabs.dart';
import 'my_test_series_screen.dart';

/// `/test-series`: opens the series on sale, or the user's own series when
/// sales are off, or a short notice when there is nothing to show.
class TestSeriesEntryScreen extends ConsumerWidget {
  const TestSeriesEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeSeriesIdProvider);
    final owned = ref.watch(ownedSeriesIdsProvider);
    final canSell = ref.watch(testSeriesCanSellProvider);

    if (activeId.isLoading || owned.isLoading || canSell.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final active = activeId.asData?.value;
    final ownedIds = owned.asData?.value ?? const <String>{};
    final sell = canSell.asData?.value ?? false;

    if (active != null && (sell || ownedIds.contains(active))) {
      return TestSeriesHomeScreen(seriesId: active);
    }
    if (ownedIds.isNotEmpty) return const MyTestSeriesScreen();
    return Scaffold(
      appBar: AppBar(title: const Text('Test Series')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text('The test series is not available right now.'),
        ),
      ),
    );
  }
}

/// Series home: Overview, Full-Length Tests, Subject-wise Tests and
/// PYQ & Current Affairs tabs.
class TestSeriesHomeScreen extends ConsumerWidget {
  const TestSeriesHomeScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(seriesBundleProvider(seriesId));
    final ownedIds = ref.watch(ownedSeriesIdsProvider).asData?.value ?? const {};
    final isHindi = ref.watch(appLanguageProvider).asData?.value == 'hi';
    final owned = ownedIds.contains(seriesId);
    final statsAsync = ref.watch(seriesStatsProvider(seriesId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            bundleAsync.asData?.value.info.displayTitle(hindi: isHindi) ?? 'Test Series',
          ),
          actions: [
            if (ownedIds.isNotEmpty)
              IconButton(
                tooltip: 'My test series',
                icon: const Icon(Icons.history_rounded),
                onPressed: () => context.push('/my-test-series'),
              ),
          ],
          // Four short labels that fit the screen width: no sideways scrolling.
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Full-Length'),
              Tab(text: 'Subjects'),
              Tab(text: 'PYQ & CA'),
            ],
          ),
        ),
        body: bundleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _LoadError(
            onRetry: () => ref.invalidate(seriesBundleProvider(seriesId)),
          ),
          data: (bundle) {
            // Keep the previous numbers on screen while stats refresh.
            final stats =
                statsAsync.value ??
                SeriesStats.compute(
                  bundle: bundle,
                  attemptList: const [],
                  answers: const [],
                );
            return TabBarView(
              children: [
                SeriesOverviewTab(
                  bundle: bundle,
                  owned: owned,
                  isHindi: isHindi,
                  stats: stats,
                ),
                SeriesFullLengthTab(
                  bundle: bundle,
                  owned: owned,
                  isHindi: isHindi,
                  stats: stats,
                ),
                SeriesSubjectsTab(bundle: bundle, isHindi: isHindi, stats: stats),
                SeriesPyqCaTab(bundle: bundle, owned: owned, stats: stats),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Couldn't load the test series. Check your connection."),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
