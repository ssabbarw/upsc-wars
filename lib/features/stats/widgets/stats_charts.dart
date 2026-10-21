import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../practice_tests/domain/practice_scope.dart';

Color statsAccuracyColor(double? accuracy) {
  if (accuracy == null) return AppColors.gray400;
  if (accuracy < 60) return AppColors.wrong;
  if (accuracy < 80) return AppColors.warning;
  return AppColors.correct;
}

/// Three rings: coverage, accuracy, and tests finished this season.
class StatsHero extends StatelessWidget {
  const StatsHero({
    super.key,
    required this.progress,
    required this.border,
    required this.coverageLabel,
    required this.accuracyLabel,
    required this.testsLabel,
    required this.answeredLabel,
  });

  final PracticeScopeProgress progress;
  final Color border;
  final String coverageLabel;
  final String accuracyLabel;
  final String testsLabel;
  final String answeredLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.surfaceContainerHighest;
    final coverage = progress.coveragePercent;
    final accuracy = progress.accuracyPercent;
    final testsTotal = progress.testsTotal;
    final testsFraction = testsTotal <= 0
        ? 0.0
        : (progress.testsDone / testsTotal).clamp(0, 1).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricRing(
                  progress: coverage == null
                      ? 0
                      : (coverage.clamp(0, 100)) / 100,
                  value: coverage == null ? '—' : '${coverage.round()}%',
                  label: coverageLabel,
                  color: AppColors.info,
                  track: track,
                ),
              ),
              Expanded(
                child: _MetricRing(
                  progress: accuracy == null
                      ? 0
                      : (accuracy.clamp(0, 100)) / 100,
                  value: accuracy == null ? '—' : '${accuracy.round()}%',
                  label: accuracyLabel,
                  color: statsAccuracyColor(accuracy),
                  track: track,
                ),
              ),
              Expanded(
                child: _MetricRing(
                  progress: testsFraction,
                  value: testsTotal <= 0
                      ? '—'
                      : '${progress.testsDone}/${progress.testsTotal}',
                  label: testsLabel,
                  color: AppColors.purple,
                  track: track,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            answeredLabel,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRing extends StatelessWidget {
  const _MetricRing({
    required this.progress,
    required this.value,
    required this.label,
    required this.color,
    required this.track,
  });

  final double progress;
  final String value;
  final String label;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return CustomPaint(
                  painter: _RingPainter(
                    progress: animated,
                    color: color,
                    track: track,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          value,
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class StatsBarChart extends StatelessWidget {
  const StatsBarChart({
    super.key,
    required this.title,
    required this.bars,
    required this.border,
  });

  final String title;
  final List<StatsBar> bars;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (bars.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                '—',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final bar in bars) _BarRow(bar: bar),
        ],
      ),
    );
  }
}

class StatsBar {
  const StatsBar({
    required this.label,
    required this.accuracy,
    required this.detail,
    this.onTap,
  });

  final String label;
  final double? accuracy;
  final String detail;
  final VoidCallback? onTap;
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.bar});

  final StatsBar bar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = statsAccuracyColor(bar.accuracy);
    final fraction = ((bar.accuracy ?? 0).clamp(0, 100)) / 100;
    return InkWell(
      onTap: bar.onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bar.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  bar.accuracy == null ? '—' : '${bar.accuracy!.round()}%',
                  style: AppTextStyles.labelSm().copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: scheme.surfaceContainerHighest),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: ColoredBox(color: color),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              bar.detail,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}
