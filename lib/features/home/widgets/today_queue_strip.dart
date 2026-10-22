import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../community/providers/open_challenge_providers.dart';
import '../providers/today_hub_provider.dart';
import '../../../l10n/l10n.dart';

class _TodayItem {
  const _TodayItem({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// Today's CA / war / challenge entries as side-by-side cards.
class TodayQueueStrip extends ConsumerWidget {
  const TodayQueueStrip({super.key});

  List<_TodayItem> _items(BuildContext context, WidgetRef ref) {
    final data = ref.watch(todayHubProvider);
    final challenges =
        ref.watch(homeOpenChallengesProvider).asData?.value ?? const [];
    final items = <_TodayItem>[];

    if (data.caShotsEnabled) {
      items.add(
        _TodayItem(
          icon: Icons.bolt_rounded,
          accent: AppColors.primary,
          title: context.l10n.todayQueueCaShots,
          subtitle: context.l10n.todayQueueCaShotsSubtitle,
          onTap: () => context.push('/ca-shot'),
        ),
      );
    }
    if (data.caEnabled && !data.paperCompleted) {
      items.add(
        _TodayItem(
          icon: Icons.article_outlined,
          accent: AppColors.info,
          title: context.l10n.todayQueueCaTest,
          subtitle: context.l10n.todayQueueCaTestSubtitle,
          onTap: () => context.push('/daily-ca'),
        ),
      );
    }
    if (data.warEnabled && !data.warSubmitted) {
      items.add(
        _TodayItem(
          icon: Icons.local_fire_department_outlined,
          accent: AppColors.wrong,
          title: context.l10n.todayQueueDailyWar,
          subtitle: context.l10n.todayQueueDailyWarSubtitle,
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
      items.add(
        _TodayItem(
          icon: Icons.emoji_events_outlined,
          accent: AppColors.warning,
          title: context.l10n.todayQueueOpenChallenge,
          subtitle: context.l10n.todayQueueOpenChallengeSubtitle,
          onTap: () => context.go(
            '/community?tab=open_challenge&highlight=${challenge.id}',
          ),
        ),
      );
    }
    return items;
  }

  void _showAll(BuildContext context, List<_TodayItem> items) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Text(
                context.l10n.todayQueueTitle,
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in items) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: item.accent.withValues(alpha: 0.15),
                    child: Icon(item.icon, color: item.accent, size: 20),
                  ),
                  title: Text(item.title, style: AppTextStyles.label()),
                  subtitle: Text(
                    item.subtitle,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    item.onTap();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _items(context, ref);
    if (items.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final preview = items.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.todayQueueTitle,
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () => _showAll(context, items),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.commonViewAll,
                    style: AppTextStyles.labelSm().copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _TodayCard(item: preview[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.item});

  final _TodayItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.gray900.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(
                        alpha: isDark ? 0.25 : 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(item.icon, size: 18, color: item.accent),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: Text(
                  item.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
