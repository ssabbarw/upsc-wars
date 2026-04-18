import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

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
    final logged = r.confidenceSureTotal +
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

  void _openTier(BuildContext context, String tier) {
    context.push('/session-confidence-review/$sessionId/$tier');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answered = _answeredScored(result);
    final logged = _loggedTotal(result);
    final coverage = _coverage(result);
    final showNudge = result.mode == 'exam' &&
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
                        'How your confidence matched outcomes',
                        style: AppTextStyles.h3().copyWith(
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap a row to review only those questions in this session.',
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
                title: 'Unlock this map next time',
                body:
                    'You did not log confidence on any of your $answered scored questions. '
                    'After each answer, use the three chips under your chosen option — it takes one tap '
                    'and powers Danger Zone, accuracy by tier, and smarter revision hints.',
              ),
            ] else if (showNudge) ...[
              const SizedBox(height: AppSpacing.md),
              _TeaserCallout(
                scheme: scheme,
                icon: Icons.auto_graph_rounded,
                title: 'Log a bit more next round',
                body:
                    'You tagged $logged of $answered scored questions (${(coverage * 100).toStringAsFixed(0)}%). '
                    'Aim for at least half — the more you log, the sharper your insights get.',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _TierInsightTile(
              scheme: scheme,
              title: AnswerConfidence.examShortLabel(AnswerConfidence.verySure),
              subtitle: 'High conviction picks',
              accent: AppColors.correct,
              total: result.confidenceSureTotal,
              correct: result.confidenceSureCorrect,
              onOpen: () => _openTier(context, AnswerConfidence.verySure),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TierInsightTile(
              scheme: scheme,
              title: AnswerConfidence.examShortLabel(AnswerConfidence.somewhatSure),
              subtitle: 'Reasoned but not certain',
              accent: AppColors.warning,
              total: result.confidenceIntelligentTotal,
              correct: result.confidenceIntelligentCorrect,
              onOpen: () => _openTier(context, AnswerConfidence.somewhatSure),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TierInsightTile(
              scheme: scheme,
              title: AnswerConfidence.examShortLabel(AnswerConfidence.guessing),
              subtitle: 'Honest long shots',
              accent: scheme.tertiary,
              total: result.confidencePureTotal,
              correct: result.confidencePureCorrect,
              onOpen: () => _openTier(context, AnswerConfidence.guessing),
            ),
          ],
        ),
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
          'Questions where you tapped Sure, Intelligent, or Pure guess after answering.',
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
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.35),
        ),
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

class _TierInsightTile extends StatelessWidget {
  const _TierInsightTile({
    required this.scheme,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.total,
    required this.correct,
    required this.onOpen,
  });

  final ColorScheme scheme;
  final String title;
  final String subtitle;
  final Color accent;
  final int total;
  final int correct;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final wrong = total - correct;
    final acc = total > 0 ? (correct * 100 / total) : null;
    final accLabel = acc == null ? '—' : '${acc.toStringAsFixed(0)}%';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: accent.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.md - 1),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTextStyles.h3().copyWith(
                                      color: scheme.onSurface,
                                      fontSize: 17,
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
                            Icon(
                              Icons.chevron_right_rounded,
                              color: accent,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _StatChip(
                              label: 'Attempted',
                              value: '$total',
                              scheme: scheme,
                            ),
                            _StatChip(
                              label: 'Correct',
                              value: '$correct',
                              scheme: scheme,
                              valueColor: AppColors.correct,
                            ),
                            _StatChip(
                              label: 'Incorrect',
                              value: '$wrong',
                              scheme: scheme,
                              valueColor: wrong > 0 ? AppColors.wrong : null,
                            ),
                            _StatChip(
                              label: 'Accuracy',
                              value: accLabel,
                              scheme: scheme,
                              emphasize: acc != null,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _OutcomeRatioBar(
                          correct: correct,
                          wrong: wrong,
                          accentCorrect: AppColors.correct,
                          accentWrong: AppColors.wrong,
                          trackColor: scheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.scheme,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final ColorScheme scheme;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.label().copyWith(
              color: valueColor ??
                  (emphasize ? scheme.primary : scheme.onSurface),
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              fontSize: emphasize ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeRatioBar extends StatelessWidget {
  const _OutcomeRatioBar({
    required this.correct,
    required this.wrong,
    required this.accentCorrect,
    required this.accentWrong,
    required this.trackColor,
  });

  final int correct;
  final int wrong;
  final Color accentCorrect;
  final Color accentWrong;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final t = correct + wrong;
    if (t == 0) {
      return Container(
        height: 12,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          'No attempts in this bucket',
          style: AppTextStyles.caption().copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (correct > 0)
              Expanded(
                flex: correct,
                child: Container(color: accentCorrect),
              ),
            if (wrong > 0)
              Expanded(
                flex: wrong,
                child: Container(color: accentWrong),
              ),
          ],
        ),
      ),
    );
  }
}
