import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import '../../../l10n/l10n.dart';

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

String _firstName(String raw, {String? fallback}) {
  final parts = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return fallback ?? appL10n.commonOpponent;
  return parts.first;
}

String _accuracyLine(({int correct, int wrong, int unanswered, int total}) c) {
  final attempted = c.correct + c.wrong;
  if (attempted <= 0) return appL10n.bsbNoAttempts;
  final pct = (100 * c.correct / attempted).round();
  return c.unanswered > 0
      ? appL10n.bsbAccUn(pct, c.correct, c.wrong, c.unanswered)
      : appL10n.bsbAcc(pct, c.correct, c.wrong);
}

String _calcSnippet(({int correct, int wrong, int unanswered, int total}) c) {
  final pos = c.correct * 2;
  if (c.wrong == 0) return '+$pos / 0';
  final neg = (c.wrong * 0.66).toStringAsFixed(2);
  return '+$pos / −$neg';
}

/// Head-to-head score summary card (context.l10n.bsbStacked).
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

    final youWon = tie || ahead;
    final oppWon = tie || !ahead;
    final playerName = _firstName(
      payload.playerName,
      fallback: appL10n.commonYou,
    );
    final opponentName = _firstName(payload.opponentName);

    final cardBg = isDark ? AppColors.surfaceSecondaryDark : Colors.white;
    final borderCol = scheme.outline.withValues(alpha: isDark ? 0.35 : 0.22);

    return Material(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: borderCol),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ConfettiPainter(isDark: isDark)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StackedUpHeader(scheme: scheme),
                const SizedBox(height: AppSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ScorePillar(
                          scheme: scheme,
                          isWinner: youWon && !tie,
                          isLoser: oppWon && !tie,
                          roleLabel: context.l10n.bsbYouCaps,
                          name: playerName,
                          score: mine,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Align(
                        alignment: Alignment.center,
                        child: _VsBadge(scheme: scheme, isDark: isDark),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ScorePillar(
                          scheme: scheme,
                          isWinner: oppWon && !tie,
                          isLoser: youWon && !tie,
                          roleLabel: null,
                          name: opponentName,
                          score: theirs,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: borderCol.withValues(alpha: 0.7)),
                const SizedBox(height: AppSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PlayerStatColumn(
                          scheme: scheme,
                          isPositive: youWon,
                          label: appL10n.commonYou,
                          score: mine,
                          calc: _calcSnippet(you),
                          accuracy: _accuracyLine(you),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: borderCol.withValues(alpha: 0.7),
                      ),
                      Expanded(
                        child: _PlayerStatColumn(
                          scheme: scheme,
                          isPositive: oppWon,
                          label: opponentName,
                          score: theirs,
                          calc: _calcSnippet(opp),
                          accuracy: _accuracyLine(opp),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DeltaSummaryPill(tie: tie, ahead: ahead, delta: delta.abs()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Victory / loss / tie banner below the score card.
class BattleResultOutcomeBanner extends StatelessWidget {
  const BattleResultOutcomeBanner({
    super.key,
    required this.playerScore,
    required this.opponentScore,
    this.spectateVerdict,
  });

  final double playerScore;
  final double opponentScore;
  final String? spectateVerdict;

  @override
  Widget build(BuildContext context) {
    final diff = playerScore - opponentScore;
    final tie = diff.abs() < 0.001;
    final won = !tie && diff > 0;

    if (won) {
      return _VictoryBanner(spectateVerdict: spectateVerdict);
    }

    final scheme = Theme.of(context).colorScheme;
    final (title, subtitle) = tie
        ? (context.l10n.bsbTieTitle, context.l10n.bsbTieSub)
        : (context.l10n.bsbLoseTitle, context.l10n.bsbLoseSub);

    final statusLine =
        spectateVerdict ??
        (tie ? context.l10n.bsbTiedPoints : context.l10n.bsoOppAheadNow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.h1().copyWith(color: scheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          statusLine,
          style: AppTextStyles.bodyMd().copyWith(
            color: AppColors.coachTrendEmerald,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VictoryBanner extends StatelessWidget {
  const _VictoryBanner({this.spectateVerdict});

  final String? spectateVerdict;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A4D3C), Color(0xFF085041), Color(0xFF063D32)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ConfettiPainter(isDark: true, dense: true),
            ),
          ),
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: 22,
                      color: AppColors.onboardingScoreMutedGreen.withValues(
                        alpha: 0.85,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 44,
                      color: const Color(0xFFFFC857),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.spa_outlined,
                      size: 22,
                      color: AppColors.onboardingScoreMutedGreen.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.bsbVictory,
                  style: AppTextStyles.h1().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.bsbOutplayed,
                  style: AppTextStyles.bodySm().copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        spectateVerdict ?? context.l10n.bsoYouAheadNow,
                        style: AppTextStyles.bodySm().copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _StackedUpHeader extends StatelessWidget {
  const _StackedUpHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.coachTrendEmerald;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.spa_outlined,
          size: 18,
          color: accent.withValues(alpha: 0.8),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.l10n.bsbStacked,
          style: AppTextStyles.label().copyWith(
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          Icons.spa_outlined,
          size: 18,
          color: accent.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.3 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'vs',
        style: AppTextStyles.caption().copyWith(
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ScorePillar extends StatelessWidget {
  const _ScorePillar({
    required this.scheme,
    required this.isWinner,
    required this.isLoser,
    required this.roleLabel,
    required this.name,
    required this.score,
  });

  final ColorScheme scheme;
  final bool isWinner;
  final bool isLoser;
  final String? roleLabel;
  final String name;
  final double score;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winAccent = AppColors.coachTrendEmerald;
    final loseAccent = AppColors.wrong;

    final accent = isWinner
        ? winAccent
        : isLoser
        ? loseAccent
        : scheme.primary;
    final bg = isWinner
        ? (isDark ? winAccent.withValues(alpha: 0.14) : AppColors.correctBg)
        : isLoser
        ? (isDark ? loseAccent.withValues(alpha: 0.12) : AppColors.wrongBg)
        : scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5);
    final borderAlpha = isWinner || isLoser ? 0.5 : 0.2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: borderAlpha)),
        color: bg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 16,
            child: roleLabel != null
                ? Center(
                    child: Text(
                      roleLabel!,
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            score.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: AppTextStyles.h1().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.05,
              color: isWinner
                  ? accent
                  : isLoser
                  ? accent
                  : scheme.onSurface,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerStatColumn extends StatelessWidget {
  const _PlayerStatColumn({
    required this.scheme,
    required this.isPositive,
    required this.label,
    required this.score,
    required this.calc,
    required this.accuracy,
  });

  final ColorScheme scheme;
  final bool isPositive;
  final String label;
  final double score;
  final String calc;
  final String accuracy;

  @override
  Widget build(BuildContext context) {
    final accent = isPositive ? AppColors.coachTrendEmerald : AppColors.wrong;
    final icon = isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$label: ${score.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySm().copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '($calc)',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            accuracy,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaSummaryPill extends StatelessWidget {
  const _DeltaSummaryPill({
    required this.tie,
    required this.ahead,
    required this.delta,
  });

  final bool tie;
  final bool ahead;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winAccent = AppColors.coachTrendEmerald;
    final loseAccent = AppColors.wrong;

    final Color accent;
    final Color bg;
    final IconData icon;
    final String text;

    if (tie) {
      accent = AppColors.gray600;
      bg = isDark ? AppColors.gray800.withValues(alpha: 0.5) : AppColors.gray50;
      icon = Icons.horizontal_rule_rounded;
      text = context.l10n.bsbTiePts;
    } else if (ahead) {
      accent = winAccent;
      bg = isDark
          ? winAccent.withValues(alpha: 0.14)
          : winAccent.withValues(alpha: 0.1);
      icon = Icons.north_rounded;
      text = context.l10n.bsbAheadBy(delta.toStringAsFixed(2));
    } else {
      accent = loseAccent;
      bg = isDark
          ? loseAccent.withValues(alpha: 0.14)
          : loseAccent.withValues(alpha: 0.08);
      icon = Icons.south_rounded;
      text = context.l10n.bsbLedBy(delta.toStringAsFixed(2));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodySm().copyWith(
                  color: accent,
                  fontWeight: FontWeight.w500,
                ),
                children: _boldDeltaSpans(text, delta, tie),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.isDark, this.dense = false});

  final bool isDark;
  final bool dense;

  static final _pieces = <_ConfettiPiece>[
    _ConfettiPiece(0.08, 0.12, 5, 3, 0.4, AppColors.coachTrendEmerald),
    _ConfettiPiece(0.18, 0.06, 4, 4, 0.9, const Color(0xFFFFC857)),
    _ConfettiPiece(0.32, 0.14, 6, 2, 1.2, AppColors.wrong),
    _ConfettiPiece(0.46, 0.08, 3, 5, 0.2, AppColors.coachTrendEmerald),
    _ConfettiPiece(0.58, 0.16, 5, 3, 1.6, const Color(0xFFFFC857)),
    _ConfettiPiece(0.72, 0.1, 4, 4, 0.7, AppColors.coachTrendEmerald),
    _ConfettiPiece(0.84, 0.14, 3, 3, 1.1, AppColors.wrong),
    _ConfettiPiece(0.92, 0.06, 5, 2, 0.5, const Color(0xFFFFC857)),
    _ConfettiPiece(0.14, 0.22, 4, 3, 1.4, AppColors.coachTrendEmerald),
    _ConfettiPiece(0.38, 0.24, 3, 4, 0.3, AppColors.wrong),
    _ConfettiPiece(0.64, 0.2, 5, 3, 1.8, const Color(0xFFFFC857)),
    _ConfettiPiece(0.78, 0.26, 4, 2, 0.6, AppColors.coachTrendEmerald),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = dense ? 0.55 : (isDark ? 0.35 : 0.45);
    for (final piece in _pieces) {
      final paint = Paint()
        ..color = piece.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final center = Offset(piece.x * size.width, piece.y * size.height);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(piece.rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.w,
        height: piece.h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.dense != dense;
  }
}

class _ConfettiPiece {
  const _ConfettiPiece(
    this.x,
    this.y,
    this.w,
    this.h,
    this.rotation,
    this.color,
  );

  final double x;
  final double y;
  final double w;
  final double h;
  final double rotation;
  final Color color;
}

List<InlineSpan> _boldDeltaSpans(String text, double delta, bool tie) {
  final d = delta.toStringAsFixed(2);
  final i = text.indexOf(d);
  if (tie || i < 0) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, i)),
    TextSpan(
      text: d,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    TextSpan(text: text.substring(i + d.length)),
  ];
}
