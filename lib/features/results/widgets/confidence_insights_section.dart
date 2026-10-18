import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';

/// Shown after tests when exam mode or any confidence was logged — includes
/// coverage nudges and tap-through to per-tier question review.
class ConfidenceInsightsSection extends StatelessWidget {
  const ConfidenceInsightsSection({
    super.key,
    required this.sessionId,
    required this.result,
  });

  final String sessionId;
  final SessionResult result;

  static bool shouldShow(SessionResult r) {
    final logged =
        r.confidenceSureTotal +
        r.confidenceIntelligentTotal +
        r.confidencePureTotal;
    return r.mode == 'exam' || logged > 0;
  }

  static int _answeredScored(SessionResult r) => r.correct + r.wrong;

  static int _loggedTotal(SessionResult r) =>
      r.confidenceSureTotal +
      r.confidenceIntelligentTotal +
      r.confidencePureTotal;

  static double _coverage(SessionResult r) {
    final a = _answeredScored(r);
    if (a <= 0) return 0;
    return (_loggedTotal(r) / a).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answered = _answeredScored(result);
    final logged = _loggedTotal(result);
    final coverage = _coverage(result);
    final showNudge =
        result.mode == 'exam' &&
        answered >= 4 &&
        coverage < 0.5 &&
        answered > 0;
    final emptyExam = result.mode == 'exam' && logged == 0 && answered > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: isDark ? 0.22 : 0.45),
            scheme.surfaceContainerLow.withValues(alpha: 0.9),
            scheme.tertiaryContainer.withValues(alpha: isDark ? 0.12 : 0.25),
          ],
        ),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.45),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: scheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence calibration',
                        style: AppTextStyles.h3().copyWith(
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.resultsMatrixHint,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (answered > 0) ...[
              const SizedBox(height: AppSpacing.md),
              _CoverageMeter(
                scheme: scheme,
                logged: logged,
                answered: answered,
                coverage: coverage,
              ),
            ],
            if (emptyExam) ...[
              const SizedBox(height: AppSpacing.md),
              _TeaserCallout(
                scheme: scheme,
                icon: Icons.touch_app_rounded,
                title: context.l10n.resultsUnlockMap,
                body: context.l10n.resultsUnlockMapBody(answered),
              ),
            ] else if (showNudge) ...[
              const SizedBox(height: AppSpacing.md),
              _TeaserCallout(
                scheme: scheme,
                icon: Icons.auto_graph_rounded,
                title: context.l10n.resultsLogMore,
                body: context.l10n.resultsLogMoreBody(
                  logged,
                  answered,
                  (coverage * 100).toStringAsFixed(0),
                ),
              ),
            ],
            if (logged > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              _CalibrationMatrix(
                scheme: scheme,
                result: result,
                onCellTap:
                    (ctx, {required tier, required outcome, required count}) {
                      if (count <= 0) return;
                      ctx.push(
                        '/session-confidence-review/$sessionId/$tier?outcome=$outcome',
                      );
                    },
              ),
              if (result.confidenceSureTotal >= 3) ...[
                const SizedBox(height: AppSpacing.md),
                _SureTierAccuracyBanner(
                  scheme: scheme,
                  sureTotal: result.confidenceSureTotal,
                  sureCorrect: result.confidenceSureCorrect,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

typedef _CalibrationCellTap =
    void Function(
      BuildContext context, {
      required String tier,
      required String outcome,
      required int count,
    });

class _CalibrationMatrix extends StatelessWidget {
  const _CalibrationMatrix({
    required this.scheme,
    required this.result,
    required this.onCellTap,
  });

  final ColorScheme scheme;
  final SessionResult result;
  final _CalibrationCellTap onCellTap;

  @override
  Widget build(BuildContext context) {
    final sureC = result.confidenceSureCorrect;
    final sureW = result.confidenceSureTotal - sureC;
    final intC = result.confidenceIntelligentCorrect;
    final intW = result.confidenceIntelligentTotal - intC;
    final pureC = result.confidencePureCorrect;
    final pureW = result.confidencePureTotal - pureC;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '',
                style: AppTextStyles.caption().copyWith(fontSize: 10),
              ),
            ),
            Expanded(
              child: _MatrixColHeader(scheme: scheme, label: 'Sure'),
            ),
            Expanded(
              child: _MatrixColHeader(scheme: scheme, label: 'Likely'),
            ),
            Expanded(
              child: _MatrixColHeader(scheme: scheme, label: 'Guess'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MatrixRowLabel(
              scheme: scheme,
              label: context.l10n.resultsMatrixCorrect,
            ),
            Expanded(
              child: _MatrixCell(
                scheme: scheme,
                count: sureC,
                tier: AnswerConfidence.verySure,
                outcome: 'correct',
                emphasizeLuck: false,
                onTap: onCellTap,
              ),
            ),
            Expanded(
              child: _MatrixCell(
                scheme: scheme,
                count: intC,
                tier: AnswerConfidence.somewhatSure,
                outcome: 'correct',
                emphasizeLuck: false,
                onTap: onCellTap,
              ),
            ),
            Expanded(
              child: _MatrixCell(
                scheme: scheme,
                count: pureC,
                tier: AnswerConfidence.guessing,
                outcome: 'correct',
                emphasizeLuck: pureC > 0,
                onTap: onCellTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MatrixRowLabel(
              scheme: scheme,
              label: context.l10n.resultsMatrixWrong,
            ),
            Expanded(
              child: _MatrixCell(
                scheme: scheme,
                count: sureW,
                tier: AnswerConfidence.verySure,
                outcome: 'wrong',
                danger: sureW > 0,
                onTap: onCellTap,
              ),
            ),
            Expanded(
              child: _MatrixCell(
                scheme: scheme,
                count: intW,
                tier: AnswerConfidence.somewhatSure,
                outcome: 'wrong',
                danger: intW > 0,
                onTap: onCellTap,
              ),
            ),
            Expanded(
              child: _MatrixCell(
                scheme: scheme,
                count: pureW,
                tier: AnswerConfidence.guessing,
                outcome: 'wrong',
                danger: false,
                onTap: onCellTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatrixColHeader extends StatelessWidget {
  const _MatrixColHeader({required this.scheme, required this.label});

  final ColorScheme scheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption().copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MatrixRowLabel extends StatelessWidget {
  const _MatrixRowLabel({required this.scheme, required this.label});

  final ColorScheme scheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({
    required this.scheme,
    required this.count,
    required this.tier,
    required this.outcome,
    required this.onTap,
    this.danger = false,
    this.emphasizeLuck = false,
  });

  final ColorScheme scheme;
  final int count;
  final String tier;
  final String outcome;
  final _CalibrationCellTap onTap;
  final bool danger;
  final bool emphasizeLuck;

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    final borderColor = danger
        ? AppColors.wrong
        : emphasizeLuck
        ? AppColors.warning
        : scheme.outlineVariant.withValues(alpha: 0.45);
    final bg = scheme.surface.withValues(alpha: 0.88);

    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '—',
            style: AppTextStyles.h3().copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    Widget? icon;
    if (danger) {
      icon = Icon(
        Icons.warning_amber_rounded,
        size: 16,
        color: AppColors.wrong,
      );
    } else if (emphasizeLuck) {
      icon = const Text('🍀', style: TextStyle(fontSize: 14));
    } else if (outcome == 'correct') {
      icon = Icon(
        Icons.check_circle_outline,
        size: 16,
        color: AppColors.correct,
      );
    } else {
      icon = Icon(
        Icons.cancel_outlined,
        size: 16,
        color: scheme.onSurfaceVariant,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () =>
              onTap(context, tier: tier, outcome: outcome, count: count),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.85),
                width: danger ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: AppTextStyles.h3().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SureTierAccuracyBanner extends StatelessWidget {
  const _SureTierAccuracyBanner({
    required this.scheme,
    required this.sureTotal,
    required this.sureCorrect,
  });

  final ColorScheme scheme;
  final int sureTotal;
  final int sureCorrect;

  @override
  Widget build(BuildContext context) {
    final pct = sureTotal == 0 ? 0.0 : (100.0 * sureCorrect / sureTotal);
    final warn = pct < 75;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: warn ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: warn
              ? scheme.error.withValues(alpha: 0.35)
              : scheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warn ? Icons.priority_high_rounded : Icons.verified_outlined,
            color: warn ? scheme.onErrorContainer : scheme.onSecondaryContainer,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              warn
                  ? context.l10n.resultsSureWarn(
                      pct.toStringAsFixed(0),
                      sureCorrect,
                      sureTotal,
                    )
                  : context.l10n.resultsSureOk(
                      pct.toStringAsFixed(0),
                      sureCorrect,
                      sureTotal,
                    ),
              style: AppTextStyles.bodySm().copyWith(
                color: warn ? scheme.onErrorContainer : scheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageMeter extends StatelessWidget {
  const _CoverageMeter({
    required this.scheme,
    required this.logged,
    required this.answered,
    required this.coverage,
  });

  final ColorScheme scheme;
  final int logged;
  final int answered;
  final double coverage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Confidence coverage',
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$logged / $answered',
              style: AppTextStyles.label().copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: coverage.clamp(0.0, 1.0),
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.resultsCoverageHint,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _TeaserCallout extends StatelessWidget {
  const _TeaserCallout({
    required this.scheme,
    required this.icon,
    required this.title,
    required this.body,
  });

  final ColorScheme scheme;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.secondary, size: 26),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
