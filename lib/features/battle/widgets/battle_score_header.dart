import 'package:flutter/material.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/battle_scoring.dart';
import 'package:upsc_wars/features/battle/widgets/battle_question_score_grid.dart';

class BattleScoreHeader extends StatelessWidget {
  const BattleScoreHeader({
    super.key,
    required this.playerName,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.playerOutcomeByQuestion,
    required this.opponentOutcomeByQuestion,
  });

  final String playerName;
  final String opponentName;
  final BattleScore playerScore;
  final BattleScore opponentScore;
  final List<bool?> playerOutcomeByQuestion;
  final List<bool?> opponentOutcomeByQuestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ScoreTile(
                  name: playerName,
                  points: playerScore.points,
                  highlight: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'VS',
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScoreTile(
                  name: opponentName,
                  points: opponentScore.points,
                  highlight: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BattleQuestionScoreGrid(
          playerName: playerName,
          opponentName: opponentName,
          playerOutcomeByQuestion: playerOutcomeByQuestion,
          opponentOutcomeByQuestion: opponentOutcomeByQuestion,
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.name,
    required this.points,
    required this.highlight,
  });

  final String name;
  final double points;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryLight : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            points.toStringAsFixed(2),
            style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
