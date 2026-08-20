import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/daily_war_badges.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';
import '../widgets/daily_war_badge_chip.dart';

/// Cabinet of every Daily War award + how many times it was earned.
class DailyWarBadgesScreen extends ConsumerWidget {
  const DailyWarBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(dailyWarBadgeTalliesProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'War Badges',
          style: DwText.dm(
            size: 18,
            weight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tallies) {
          final earned = tallies.values.fold<int>(0, (a, b) => a + b);
          final kinds = tallies.values.where((n) => n > 0).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                '$kinds badges · $earned total earns',
                style: DwText.dm(
                  size: 13,
                  weight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Counts sync from your Static War nights — kept on this device and in the cloud.',
                style: DwText.dm(
                  size: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'EFFORT',
                style: DwText.eyebrow(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              _BadgeGrid(
                ids: DailyWarBadges.catalogOrder
                    .where(DailyWarBadges.isEffortAward)
                    .toList(),
                tallies: tallies,
              ),
              const SizedBox(height: 22),
              Text(
                'NIGHT AWARDS',
                style: DwText.eyebrow(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              _BadgeGrid(
                ids: DailyWarBadges.catalogOrder
                    .where((id) => !DailyWarBadges.isEffortAward(id))
                    .toList(),
                tallies: tallies,
              ),
              const SizedBox(height: 22),
              Text(
                'STREAK TIERS',
                style: DwText.eyebrow(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              _BadgeGrid(
                ids: DailyWarBadges.tierIds,
                tallies: tallies,
                isTier: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({
    required this.ids,
    required this.tallies,
    this.isTier = false,
  });

  final List<String> ids;
  final Map<String, int> tallies;
  final bool isTier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.maxWidth >= 420 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ids.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, i) {
            final id = ids[i];
            final count = tallies[id] ?? 0;
            final earned = count > 0;
            final label = isTier
                ? (DailyWarBadges.tierLabels[id] ?? id)
                : DailyWarBadges.labelForAward(id);
            final blurb = isTier
                ? 'Consistency ladder'
                : DailyWarBadges.blurbForAward(id);

            return Opacity(
              opacity: earned ? 1 : 0.42,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                decoration: BoxDecoration(
                  color: DwColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: earned
                        ? DwColors.teal.withValues(alpha: 0.35)
                        : DwColors.borderOnDark,
                  ),
                ),
                child: Column(
                  children: [
                    DailyWarBadgeChip(badgeId: id, size: 52),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DwText.dm(
                        size: 12,
                        weight: FontWeight.w800,
                        color: DwColors.onDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blurb,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DwText.dm(
                        size: 10,
                        weight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      earned ? '×$count' : '—',
                      style: DwText.dm(
                        size: 13,
                        weight: FontWeight.w800,
                        color: earned ? DwColors.teal : DwColors.onDarkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
