import 'package:flutter/material.dart';

import '../domain/daily_war_badges.dart';

/// Small hexagonal badge image for leaderboard rows.
class DailyWarBadgeChip extends StatelessWidget {
  const DailyWarBadgeChip({
    super.key,
    required this.badgeId,
    this.size = 22,
  });

  /// Tier id (`recruit`…) or award id (`clean_sweep`…).
  final String badgeId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = DailyWarBadges.assetForTier(badgeId) ??
        DailyWarBadges.assetForAward(badgeId);
    if (asset == null) return _MissingBadge(size: size);
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _MissingBadge(size: size),
    );
  }
}

class _MissingBadge extends StatelessWidget {
  const _MissingBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.workspace_premium_rounded,
        size: size * 0.72,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Badge with label underneath (profile sheet).
class DailyWarBadgeTile extends StatelessWidget {
  const DailyWarBadgeTile({
    super.key,
    required this.badgeId,
    this.size = 56,
  });

  final String badgeId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTier = DailyWarBadges.tierIds.contains(badgeId);
    final label = isTier
        ? (DailyWarBadges.tierLabels[badgeId] ?? badgeId)
        : DailyWarBadges.labelForAward(badgeId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DailyWarBadgeChip(badgeId: badgeId, size: size),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
