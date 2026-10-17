import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/series_stats.dart';
import '../domain/test_series_models.dart';

enum SeriesTileState { locked, upcoming, available, inProgress, attempted }

SeriesTileState seriesTileState({
  required SeriesTest test,
  required bool owned,
  required bool inProgress,
  required SeriesTestAttempt? attempt,
  required DateTime now,
}) {
  if (!owned && !test.isFree) return SeriesTileState.locked;
  if (attempt != null) return SeriesTileState.attempted;
  if (inProgress) return SeriesTileState.inProgress;
  if (!test.isAvailableAt(now)) return SeriesTileState.upcoming;
  return SeriesTileState.available;
}

/// "Unlocks 1 Nov", or "Publishing soon" once the date has passed but the
/// paper is still waiting for its current-affairs questions.
String seriesUnlockLabel(SeriesTest test, DateTime now) {
  if (test.unlockAt.isAfter(now)) {
    return 'Unlocks ${DateFormat('d MMM').format(test.unlockAt)}';
  }
  return 'Publishing soon';
}

/// Availability line shown under a test that is not yet attempted.
///
/// Future-dated tests say when they open. Dated releases (monthly current
/// affairs, mocks) that are already live say since when. Evergreen tests that
/// have been open since launch show nothing.
String? seriesAvailabilityLabel(SeriesTest test, DateTime now) {
  if (test.unlockAt.isAfter(now)) {
    return 'Available from ${DateFormat('d MMM y').format(test.unlockAt)}';
  }
  if (test.isCurrentAffairs || test.isFullLength) {
    return 'Live since ${DateFormat('d MMM').format(test.unlockAt)}';
  }
  return null;
}

/// "112 / 200" style UPSC marks for an attempt.
String seriesMarksLabel(double net, double max) =>
    '${net.round()} / ${max.round()}';

/// One test row: icon, title, a short line of context and a state-driven
/// action (Review / Start / Continue / unlock date). Locked tests show a lock
/// in the premium colour.
class SeriesTestTile extends StatelessWidget {
  const SeriesTestTile({
    super.key,
    required this.test,
    required this.state,
    required this.attempt,
    required this.now,
    required this.onTap,
  });

  final SeriesTest test;
  final SeriesTileState state;
  final SeriesTestAttempt? attempt;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final meta = '${test.questionCount} Q · ${test.durationMins} min';
    final theme = (test.theme ?? '').trim();
    final availability = seriesAvailabilityLabel(test, now);
    final String subtitle;
    switch (state) {
      case SeriesTileState.attempted:
        final a = attempt!;
        final done = a.completedAt;
        subtitle = [
          if (done != null) DateFormat('d MMM y').format(done),
          '${(a.accuracy * 100).round()}% accuracy',
        ].join(' · ');
      case SeriesTileState.upcoming:
      case SeriesTileState.locked:
      case SeriesTileState.available:
        subtitle = [
          if (theme.isNotEmpty) theme,
          meta,
          ?availability,
        ].join('\n');
      case SeriesTileState.inProgress:
        subtitle = 'In progress · $meta';
    }

    final (IconData icon, Color color) = switch (state) {
      SeriesTileState.attempted => (Icons.check_rounded, AppColors.primary),
      SeriesTileState.inProgress => (Icons.play_arrow_rounded, AppColors.info),
      SeriesTileState.upcoming => (Icons.schedule_rounded, scheme.onSurfaceVariant),
      SeriesTileState.locked => (Icons.lock_rounded, AppColors.warning),
      SeriesTileState.available => (Icons.description_outlined, AppColors.info),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardListGap),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              test.title,
                              style: AppTextStyles.bodyMd().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (test.isFree) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const _FreeChip(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Trailing(state: state, attempt: attempt, test: test, now: now),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.state,
    required this.attempt,
    required this.test,
    required this.now,
  });

  final SeriesTileState state;
  final SeriesTestAttempt? attempt;
  final SeriesTest test;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (state) {
      case SeriesTileState.attempted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              seriesMarksLabel(attempt!.netMarks, attempt!.maxMarks),
              style: AppTextStyles.labelSm().copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const _Pill('Review', color: AppColors.primary),
          ],
        );
      case SeriesTileState.inProgress:
        return const _Pill('Continue', color: AppColors.info);
      case SeriesTileState.available:
        return const _Pill('Start', color: AppColors.info);
      case SeriesTileState.locked:
        return Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        );
      case SeriesTileState.upcoming:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Text(
            // The full date is in the subtitle; keep this short.
            test.unlockAt.isAfter(now)
                ? DateFormat('d MMM').format(test.unlockAt)
                : 'Soon',
            textAlign: TextAlign.end,
            style: AppTextStyles.labelSm().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm().copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FreeChip extends StatelessWidget {
  const _FreeChip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? AppColors.correctBgDark : AppColors.correctBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'FREE',
        style: AppTextStyles.labelSm().copyWith(
          color: isDark ? AppColors.correctTextDark : AppColors.correctText,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
