import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../practice_tests/providers/insight_improve_delta_provider.dart';

/// After an Improve-score test: whether topic/trap accuracy went up.
class InsightImproveResultCard extends ConsumerWidget {
  const InsightImproveResultCard({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightImproveDeltaProvider(sessionId));
    return async.maybeWhen(
      data: (delta) {
        if (delta == null) return const SizedBox.shrink();
        return _Card(delta: delta);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.delta});

  final InsightImproveDelta delta;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = delta.label;
    final title = delta.isFirst
        ? l10n.practiceImproveResultFirst
        : delta.improved
        ? l10n.practiceImproveResultUp
        : delta.declined
        ? l10n.practiceImproveResultDown
        : l10n.practiceImproveResultFlat;
    final body = delta.isFirst
        ? l10n.practiceImproveResultBodyFirst(label, delta.afterPercent)
        : l10n.practiceImproveResultBody(
            label,
            delta.beforePercent ?? 0,
            delta.afterPercent,
          );

    final Color bg;
    final Color fg;
    final IconData icon;
    if (delta.isFirst) {
      bg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
      fg = isDark ? AppColors.infoTextDark : AppColors.infoText;
      icon = Icons.flag_outlined;
    } else if (delta.improved) {
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
      icon = Icons.trending_up_rounded;
    } else if (delta.declined) {
      bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
      fg = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
      icon = Icons.trending_down_rounded;
    } else {
      bg = scheme.surfaceContainerLow;
      fg = scheme.onSurface;
      icon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.bodySm().copyWith(
                    color: fg,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
