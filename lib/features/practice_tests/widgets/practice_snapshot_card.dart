import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_subject_insights.dart';

/// Season snapshot: accuracy ring, Sure / Educated-guess rows, and tests.
class PracticeSnapshotCard extends StatelessWidget {
  const PracticeSnapshotCard({
    super.key,
    required this.progress,
    required this.insights,
    this.ctaLabel,
    this.onCta,
  });

  final PracticeScopeProgress progress;
  final AsyncValue<PracticeSubjectInsights> insights;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAnswers = progress.answered > 0;
    final accuracy = progress.accuracyPercent;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onCta,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AccuracyRing(
                      progress: accuracy == null ? 0 : accuracy / 100,
                      label: accuracy == null ? '—' : '${accuracy.round()}%',
                      caption: context.l10n.practiceSnapshotAccuracy,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: !hasAnswers
                          ? Text(
                              context.l10n.practiceSnapshotEmpty,
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            )
                          : insights.when(
                              loading: () => const _LensSkeleton(),
                              error: (_, _) => Text(
                                context.l10n.practiceInsightsFailed,
                                style: AppTextStyles.bodySm().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              data: (data) => _LensStack(insights: data),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.practiceTestsProgress(
                              progress.testsDone,
                              progress.testsTotal,
                            ),
                            style: AppTextStyles.labelSm().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress.testsTotal == 0
                                        ? 0
                                        : progress.testsDone /
                                              progress.testsTotal,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? AppColors.gray800
                                        : AppColors.gray50,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              if (onCta != null && ctaLabel != null) ...[
                                const SizedBox(width: AppSpacing.md),
                                _SnapshotCta(label: ctaLabel!),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapshotCta extends StatelessWidget {
  const _SnapshotCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm().copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
      ],
    );
  }
}

class _LensStack extends StatelessWidget {
  const _LensStack({required this.insights});

  final PracticeSubjectInsights insights;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _LensRow(
          icon: Icons.check_circle_rounded,
          iconColor: isDark ? AppColors.correctTextDark : AppColors.correct,
          iconFill: isDark ? AppColors.correctBgDark : AppColors.correctBg,
          title: context.l10n.practiceLensSure,
          correct: insights.sureCorrect,
          wrong: insights.sureWrong,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        _LensRow(
          icon: Icons.lightbulb_rounded,
          iconColor: isDark ? AppColors.purpleTextDark : AppColors.purple,
          iconFill: isDark ? AppColors.purpleBgDark : AppColors.purpleBg,
          title: context.l10n.practiceLensGuess,
          correct: insights.educatedGuessCorrect,
          wrong: insights.educatedGuessWrong,
        ),
      ],
    );
  }
}

class _LensRow extends StatelessWidget {
  const _LensRow({
    required this.icon,
    required this.iconColor,
    required this.iconFill,
    required this.title,
    required this.correct,
    required this.wrong,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconFill;
  final String title;
  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = correct + wrong;
    final wrongPct = total == 0 ? null : (100 * wrong / total).round();
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconFill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.l10n.practiceLensSplit(correct, wrong),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (wrongPct != null) ...[
          const SizedBox(width: AppSpacing.xs),
          _WrongBadge(percent: wrongPct),
        ],
      ],
    );
  }
}

class _WrongBadge extends StatelessWidget {
  const _WrongBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            '$percent%',
            style: AppTextStyles.labelSm().copyWith(
              color: text,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            context.l10n.practiceLensWrong.toLowerCase(),
            style: AppTextStyles.caption().copyWith(
              color: text,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({
    required this.progress,
    required this.label,
    required this.caption,
  });

  final double progress;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 92,
      height: 92,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: AppColors.primary,
              track: isDark
                  ? AppColors.correctBgDark.withValues(alpha: 0.55)
                  : AppColors.correctBg,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.h2().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption.toLowerCase(),
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
    const stroke = 10.0;
    final arc = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * progress,
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

class _LensSkeleton extends StatelessWidget {
  const _LensSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar() => Container(
      height: 36,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
    return Column(
      children: [
        bar(),
        const SizedBox(height: AppSpacing.md),
        bar(),
      ],
    );
  }
}
