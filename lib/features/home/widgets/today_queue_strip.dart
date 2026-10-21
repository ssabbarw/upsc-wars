import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../community/providers/open_challenge_providers.dart';
import '../domain/daily_rituals.dart';
import '../providers/today_hub_provider.dart';
import '../../../l10n/l10n.dart';

/// Pending items for today. Hidden when nothing is left to do.
class TodayQueueStrip extends ConsumerWidget {
  const TodayQueueStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(todayHubProvider);
    final opened =
        ref.watch(dailyRitualsOpenedProvider).asData?.value ?? const {};
    final challenges =
        ref.watch(homeOpenChallengesProvider).asData?.value ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    if (data.caShotsEnabled && !opened.contains(DailyRitualIds.caShots)) {
      rows.add(
        _Row(
          icon: Icons.bolt_outlined,
          title: context.l10n.todayQueueCaShots,
          onTap: () => context.push('/ca-shot'),
        ),
      );
    }
    if (data.caEnabled && !data.paperCompleted) {
      rows.add(
        _Row(
          icon: Icons.article_outlined,
          title: context.l10n.todayQueueCaTest,
          onTap: () => context.push('/daily-ca'),
        ),
      );
    }
    if (data.warEnabled && !data.warSubmitted) {
      rows.add(
        _Row(
          icon: Icons.local_fire_department_outlined,
          title: context.l10n.todayQueueDailyWar,
          onTap: () => context.push('/daily-war'),
        ),
      );
    }
    final live = [
      for (final c in challenges)
        if (c.liveUntil == null || c.liveUntil!.isAfter(DateTime.now())) c,
    ];
    if (live.isNotEmpty) {
      final challenge = live.first;
      rows.add(
        _Row(
          icon: Icons.emoji_events_outlined,
          title: context.l10n.todayQueueOpenChallenge,
          onTap: () => context.go(
            '/community?tab=open_challenge&highlight=${challenge.id}',
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.todayQueueTitle,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          rows[i],
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
