import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../domain/daily_war_badges.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_badge_chip.dart';

/// War badges under the calendar hub — earned first, then locked.
class DailyWarEarnedBadgesSection extends ConsumerWidget {
  const DailyWarEarnedBadgesSection({super.key});

  static const _catalog = <String>[
    ...DailyWarBadges.catalogOrder,
    ...DailyWarBadges.tierIds,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(dailyWarBadgeTalliesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 0.5,
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Earned badges',
          style: AppTextStyles.h3().copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => const _EarnedBadgesShimmer(),
          error: (e, _) => Text(
            'Could not load badges: $e',
            style: AppTextStyles.bodySm().copyWith(color: scheme.error),
          ),
          data: (tallies) {
            final earnedIds = _catalog
                .where((id) => (tallies[id] ?? 0) > 0)
                .toList();
            final lockedIds = _catalog
                .where((id) => (tallies[id] ?? 0) <= 0)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (earnedIds.isEmpty)
                  Text(
                    'You have not yet earned a badge',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final id in earnedIds)
                        _BadgeChip(
                          badgeId: id,
                          count: tallies[id] ?? 0,
                          earned: true,
                        ),
                    ],
                  ),
                if (lockedIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final id in lockedIds)
                        _BadgeChip(
                          badgeId: id,
                          count: 0,
                          earned: false,
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EarnedBadgesShimmer extends StatelessWidget {
  const _EarnedBadgesShimmer();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ShimmerBox(width: 132, height: 44, borderRadius: 10),
        ShimmerBox(width: 118, height: 44, borderRadius: 10),
        ShimmerBox(width: 148, height: 44, borderRadius: 10),
        ShimmerBox(width: 110, height: 44, borderRadius: 10),
        ShimmerBox(width: 140, height: 44, borderRadius: 10),
        ShimmerBox(width: 124, height: 44, borderRadius: 10),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.badgeId,
    required this.count,
    required this.earned,
  });

  final String badgeId;
  final int count;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTier = DailyWarBadges.tierIds.contains(badgeId);
    final label = isTier
        ? (DailyWarBadges.tierLabels[badgeId] ?? badgeId)
        : DailyWarBadges.labelForAward(badgeId);
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.55);

    final chip = Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: earned
            ? scheme.surface
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: earned
              ? DwColors.teal.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: earned
                  ? const Color(0xFF111111)
                  : scheme.onSurface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DailyWarBadgeChip(badgeId: badgeId, size: 34),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: earned ? scheme.onSurface : muted,
            ),
          ),
          if (earned && count > 1) ...[
            const SizedBox(width: 4),
            Text(
              '×$count',
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: DwColors.teal,
              ),
            ),
          ],
        ],
      ),
    );

    if (earned) return chip;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Opacity(opacity: 0.55, child: chip),
    );
  }
}
