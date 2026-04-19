import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';

({int correct, int wrong, int unanswered, int total}) _outcomeCounts(
  List<bool?> outcomes,
) {
  var correct = 0;
  var wrong = 0;
  var unanswered = 0;
  for (final e in outcomes) {
    if (e == true) {
      correct++;
    } else if (e == false) {
      wrong++;
    } else {
      unanswered++;
    }
  }
  return (
    correct: correct,
    wrong: wrong,
    unanswered: unanswered,
    total: outcomes.length,
  );
}

String _shortName(String raw, {int max = 14}) {
  final t = raw.trim();
  if (t.length <= max) return ("\n\n$t\n");
  return '\n\n${t.substring(0, max - 1)}…\n';
}

String _accuracyLine(({int correct, int wrong, int unanswered, int total}) c) {
  final attempted = c.correct + c.wrong;
  if (attempted <= 0) return 'no scored attempts';
  final pct = (100 * c.correct / attempted).round();
  return '$pct% accuracy · ${c.correct} correct, ${c.wrong} wrong'
      '${c.unanswered > 0 ? ', ${c.unanswered} unanswered' : ''}';
}

String _calcSnippet(({int correct, int wrong, int unanswered, int total}) c) {
  final pos = c.correct * 2;
  if (c.wrong == 0) return '+$pos / 0';
  final neg = (c.wrong * 0.66).toStringAsFixed(2);
  return '+$pos / −$neg';
}

/// Head-to-head score summary: duel row + readable comparison (replaces two full cards).
class BattleResultScoreComparison extends StatelessWidget {
  const BattleResultScoreComparison({super.key, required this.payload});

  final BattleResultPayload payload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final you = _outcomeCounts(payload.playerOutcomeByQuestion);
    final opp = _outcomeCounts(payload.opponentOutcomeByQuestion);
    final mine = payload.playerScore;
    final theirs = payload.opponentScore;
    final delta = mine - theirs;
    final tie = delta.abs() < 0.005;
    final ahead = delta > 0;

    final winnerAccent = AppColors.coachTrendEmerald;
    final youEmph = tie || ahead;
    final oppEmph = tie || !ahead;
    final youAccent = tie
        ? scheme.primary
        : (ahead ? winnerAccent : scheme.outline);
    final oppAccent = tie
        ? scheme.primary
        : (ahead ? scheme.outline : winnerAccent);

    final cardBg = isDark ? AppColors.surfaceTertiaryDark : AppColors.gray100;
    final borderCol = scheme.outline.withValues(alpha: isDark ? 0.4 : 0.28);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: borderCol),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How you stacked up',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label().copyWith(
                    letterSpacing: 1.15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ScorePillar(
                          scheme: scheme,
                          emphasize: youEmph,
                          accent: youAccent,
                          label: 'You',
                          name: _shortName(payload.playerName),
                          score: mine,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: isDark ? 0.4 : 0.65),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                'VS',
                                style: AppTextStyles.caption().copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _ScorePillar(
                          scheme: scheme,
                          emphasize: oppEmph,
                          accent: oppAccent,
                          label: 'Opponent',
                          name: _shortName(payload.opponentName),
                          score: theirs,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: borderCol.withValues(alpha: 0.65)),
                const SizedBox(height: AppSpacing.md),
                Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurface,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'You',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' : ${mine.toStringAsFixed(2)}\n'
                            '(${_calcSnippet(you)})\n→ ${_accuracyLine(you)}). ',
                      ),
                      TextSpan(
                        text: _shortName(payload.opponentName, max: 22),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' ${theirs.toStringAsFixed(2)} '
                            '(${_calcSnippet(opp)} → ${_accuracyLine(opp)}). ',
                      ),
                      if (tie)
                        TextSpan(
                          text: '\nThat is a draw on points.',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (ahead)
                        TextSpan(
                          text:
                              '\nYou were ahead by ${delta.abs().toStringAsFixed(2)} points.',
                          style: TextStyle(
                            color: winnerAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        TextSpan(
                          text:
                              '\nThey led by ${delta.abs().toStringAsFixed(2)} points.',
                          style: TextStyle(
                            color: AppColors.wrong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScorePillar extends StatelessWidget {
  const _ScorePillar({
    required this.scheme,
    required this.emphasize,
    required this.accent,
    required this.label,
    required this.name,
    required this.score,
  });

  final ColorScheme scheme;
  final bool emphasize;
  final Color accent;
  final String label;
  final String name;
  final double score;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: emphasize
              ? accent.withValues(alpha: 0.55)
              : scheme.outline.withValues(alpha: isDark ? 0.25 : 0.18),
          width: emphasize ? 1.6 : 1,
        ),
        color: emphasize
            ? accent.withValues(alpha: isDark ? 0.12 : 0.08)
            : scheme.surface.withValues(alpha: isDark ? 0.2 : 0.55),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            score.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: AppTextStyles.h1().copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: emphasize ? accent : scheme.onSurface,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'net',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
