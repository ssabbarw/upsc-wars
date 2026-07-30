import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
}

const _games = [
  _GameEntry(
    title: 'Timeline Sorter',
    description: 'Put events in the right order.',
    route: '/games/timeline-sorter',
    icon: Icons.timeline_rounded,
  ),
  _GameEntry(
    title: 'Odd One Out',
    description: "Four items. One doesn't belong.",
    route: '/games/odd-one-out',
    icon: Icons.filter_alt_outlined,
  ),
  _GameEntry(
    title: 'Fact or Bluff',
    description: 'Five seconds. Trust your gut.',
    route: '/games/fact-or-bluff',
    icon: Icons.bolt_outlined,
  ),
  _GameEntry(
    title: 'Connect the Dots',
    description: 'Find the hidden link.',
    route: '/games/connect-the-dots',
    icon: Icons.hub_outlined,
  ),
  _GameEntry(
    title: '1v1 Duel',
    description: 'One phone, two players, fastest correct answer wins.',
    route: '/games/duel',
    icon: Icons.sports_esports_outlined,
  ),
];

class GamesHubScreen extends HookConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Games', style: AppTextStyles.h2()),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: _games.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.cardListGap),
                itemBuilder: (context, index) {
                  final game = _games[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(game.route),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Ink(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryDeep.withValues(alpha: 0.18)
                              : AppColors.primaryLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                game.icon,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.title,
                                    style: AppTextStyles.label().copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    game.description,
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
