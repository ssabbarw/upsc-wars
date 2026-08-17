import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_revision.dart';
import '../domain/start_daily_drill.dart';
import '../providers/daily_drill_provider.dart';

/// Missed vs saved. Returns after the session closes, or immediately on dismiss.
Future<void> showDailyRevisionChoiceSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String source,
  bool allowMixedFallback = false,
}) async {
  final drill = await ref.read(dailyDrillProvider.future);
  if (!context.mounted || drill == null) return;

  if (!drill.hasAnyPool && allowMixedFallback) {
    await startDailyDrill(
      context: context,
      ref: ref,
      subject: drill.subject,
      source: source,
      completedToday: drill.completedToday,
    );
    return;
  }

  final pool = await showModalBottomSheet<DailyRevisionPool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DailyRevisionChoiceSheet(state: drill),
  );
  if (pool == null || !context.mounted) return;
  await startRevisionDrill(
    context: context,
    ref: ref,
    pool: pool,
    uuids: drill.uuidsFor(pool),
    source: source,
    completedToday: drill.completedToday,
  );
}

class _DailyRevisionChoiceSheet extends StatelessWidget {
  const _DailyRevisionChoiceSheet({required this.state});

  final DailyDrillState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        sheetBottomPadding(context),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'What do you want back?',
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  state.hasAnyPool
                      ? 'The ones that got away, or the ones you marked.'
                      : 'Misses and bookmarks land here after you write.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PoolTile(
                  icon: Icons.replay_rounded,
                  title: 'Missed',
                  subtitle: state.hasWrongs
                      ? '${state.wrongCount} you got wrong'
                      : 'None yet',
                  cta: DailyRevision.tryCta(state.wrongCount),
                  enabled: state.hasWrongs,
                  borderColor: borderColor,
                  onTap: () =>
                      Navigator.pop(context, DailyRevisionPool.missed),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PoolTile(
                  icon: Icons.bookmark_rounded,
                  title: 'Saved',
                  subtitle: state.hasBookmarks
                      ? '${state.bookmarkCount} you bookmarked'
                      : 'None yet',
                  cta: DailyRevision.tryCta(state.bookmarkCount),
                  enabled: state.hasBookmarks,
                  borderColor: borderColor,
                  onTap: () =>
                      Navigator.pop(context, DailyRevisionPool.saved),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoolTile extends StatelessWidget {
  const _PoolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.enabled,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final bool enabled;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: enabled
          ? (isDark
                ? AppColors.primaryDeep.withValues(alpha: 0.22)
                : AppColors.primaryLight.withValues(alpha: 0.55))
          : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : borderColor.withValues(alpha: 0.35),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? AppColors.primaryDark
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                cta,
                style: AppTextStyles.labelSm().copyWith(
                  color: enabled
                      ? AppColors.primaryDark
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
