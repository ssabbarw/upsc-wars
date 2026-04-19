import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:upsc_wars/core/constants/subject_constants.dart';
import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';

/// Post-test summary for the web player: **this run only** (no history / coach).
enum WebPlayerResultsExit { review, reattempt }

TextStyle _advancedInsightsSectionHeading(ColorScheme scheme) =>
    AppTextStyles.bodySm().copyWith(
      fontWeight: FontWeight.bold,
      color: scheme.onSurface,
    );

Widget _resultConfLine(ColorScheme scheme, String label, int total, int correct) {
  if (total <= 0) {
    return Text(
      '$label: —',
      style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
    );
  }
  final acc = (100 * correct / total).round();
  return Text(
    '$label: $acc% accurate ($correct/$total)',
    style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
  );
}

/// Same shell as in-app [ResultsScreen] / [_CoachSurfaceCard].
class _WebPlayerCoachSurfaceCard extends StatelessWidget {
  const _WebPlayerCoachSurfaceCard({
    required this.scheme,
    required this.isDark,
    required this.child,
  });

  final ColorScheme scheme;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

/// Mirrors [_ScoreTrendCard] in session summary coach (hero net + accuracy pill).
class _WebPlayerScoreHeroCard extends StatelessWidget {
  const _WebPlayerScoreHeroCard({
    required this.result,
    required this.scheme,
    required this.isDark,
  });

  final SessionResult result;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final attempted = result.correct + result.wrong;
    final net = result.netScore;
    final netColor = net >= 0 ? AppColors.coachTrendEmerald : AppColors.wrong;
    final accLabel = attempted == 0 ? '—' : '${result.accuracy.round()}%';

    return _WebPlayerCoachSurfaceCard(
      scheme: scheme,
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You have scored',
              textAlign: TextAlign.center,
              style: AppTextStyles.label().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 200),
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      netColor.withValues(alpha: isDark ? 0.14 : 0.10),
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.45 : 0.65,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: netColor.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  net.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2().copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: netColor,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodySm().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: '('),
                  TextSpan(
                    text: '+${result.correct * 2}',
                    style: const TextStyle(color: AppColors.coachTrendEmerald),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: result.wrong == 0
                        ? '0'
                        : '-${(result.wrong * 0.66).toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.wrong),
                  ),
                  const TextSpan(text: ')'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.35 : 0.55,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: AppTextStyles.bodySm().copyWith(height: 1.35),
                  children: [
                    TextSpan(
                      text: 'Accuracy: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: accLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' (${result.correct}/${result.questionCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Improvement trends, revision queue, and topic breakdowns '
              'are available in the UPSC Wars app when you practice signed in.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (attempted == 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'You did not attempt any scored questions in this run. '
                'Try again when you are ready.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Same layout as [_DangerZoneCard] (empty vs alert), with optional review CTA.
class _WebPlayerDangerZoneCard extends StatelessWidget {
  const _WebPlayerDangerZoneCard({
    required this.result,
    required this.scheme,
    required this.isDark,
    this.onReviewDangerZone,
  });

  final SessionResult result;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback? onReviewDangerZone;

  @override
  Widget build(BuildContext context) {
    final n = result.dangerZoneWrongCount;
    final marks = result.dangerZoneMarksEstimate;
    if (n <= 0) {
      return _WebPlayerCoachSurfaceCard(
        scheme: scheme,
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.correct,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Danger Zone questions! When you were confident, you stayed accurate.',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bg = isDark
        ? AppColors.wrongBgDark
        : AppColors.coachDangerSurfaceLight;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coachDangerBorder, width: 3),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '⚠️  DANGER ZONE',
            style: AppTextStyles.label().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.wrongTextDark
                  : AppColors.coachDangerTitleText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$n Confident Mistake${n == 1 ? '' : 's'}',
            style: AppTextStyles.h2().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.wrongTextDark
                  : AppColors.coachDangerTitleText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real exam cost: -${marks.toStringAsFixed(2)} marks',
            style: AppTextStyles.bodyMd().copyWith(
              fontSize: 14,
              color: AppColors.wrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'These are rank killers. You thought you knew, but didn\'t.',
            style: AppTextStyles.bodySm().copyWith(
              fontSize: 14,
              color: isDark
                  ? AppColors.wrongTextDark
                  : AppColors.coachDangerTitleText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (onReviewDangerZone != null) ...[
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coachDangerCtaFill,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onReviewDangerZone,
                child: Text(
                  'Review Danger Zone',
                  style: AppTextStyles.label().copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else
            Text(
              'Use “Review with explanations” below to revisit these questions.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}

class WebPlayerResultsScreen extends StatelessWidget {
  const WebPlayerResultsScreen({
    super.key,
    required this.result,
    this.onReviewDangerZone,
  });

  final SessionResult result;
  final VoidCallback? onReviewDangerZone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displaySubject =
        SubjectConstants.bySlug(result.subject)?.displayName ?? result.subject;
    final attempted = result.correct + result.wrong;
    final modeLabel = result.mode == 'exam' ? 'Exam' : 'Learning';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session summary',
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          displaySubject,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$modeLabel · ${result.questionCount} question${result.questionCount == 1 ? '' : 's'}',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _WebPlayerScoreHeroCard(
                        result: result,
                        scheme: scheme,
                        isDark: isDark,
                      ),
                      if (attempted > 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        _WebPlayerDangerZoneCard(
                          result: result,
                          scheme: scheme,
                          isDark: isDark,
                          onReviewDangerZone: onReviewDangerZone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: AppColors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            title: Text(
                              'View detailed performance breakdown',
                              style: AppTextStyles.label().copyWith(
                                color: AppColors.summaryCtaBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Confidence accuracy',
                                      style: _advancedInsightsSectionHeading(
                                        scheme,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: _resultConfLine(
                                        scheme,
                                        'Confident',
                                        result.confidenceSureTotal,
                                        result.confidenceSureCorrect,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: _resultConfLine(
                                        scheme,
                                        'Intelligent guess',
                                        result.confidenceIntelligentTotal,
                                        result.confidenceIntelligentCorrect,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: _resultConfLine(
                                        scheme,
                                        'Pure guess',
                                        result.confidencePureTotal,
                                        result.confidencePureCorrect,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Attempts (this run)',
                                      style: _advancedInsightsSectionHeading(
                                        scheme,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Correct: ${result.correct} · Wrong: ${result.wrong} · '
                                      'Unattempted: ${result.unattempted}'
                                      '${result.timedOut > 0 ? ' · Timed out: ${result.timedOut}' : ''}',
                                      style: AppTextStyles.bodySm().copyWith(
                                        color: scheme.onSurface,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Net score uses +2 per correct and −0.66 per wrong.',
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
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(
                          WebPlayerResultsExit.review,
                        ),
                        style: WebPlayerUiTokens.primaryCta(context),
                        child: const Text('Review with explanations'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(
                          WebPlayerResultsExit.reattempt,
                        ),
                        style: WebPlayerUiTokens.outlineFullWidth(context),
                        child: const Text('Reattempt'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
