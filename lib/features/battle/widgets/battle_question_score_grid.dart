import 'package:flutter/material.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

class BattleQuestionScoreGrid extends StatelessWidget {
  const BattleQuestionScoreGrid({
    super.key,
    required this.playerName,
    required this.opponentName,
    required this.playerOutcomeByQuestion,
    required this.opponentOutcomeByQuestion,
  });

  final String playerName;
  final String opponentName;
  final List<bool?> playerOutcomeByQuestion;
  final List<bool?> opponentOutcomeByQuestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  playerName,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  opponentName,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'You',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < playerOutcomeByQuestion.length; i++)
                _QuestionOutcomeCircle(
                  questionNumber: i + 1,
                  outcome: playerOutcomeByQuestion[i],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Opponent',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < opponentOutcomeByQuestion.length; i++)
                _QuestionOutcomeCircle(
                  questionNumber: i + 1,
                  outcome: opponentOutcomeByQuestion[i],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionOutcomeCircle extends StatelessWidget {
  const _QuestionOutcomeCircle({
    required this.questionNumber,
    required this.outcome,
  });

  final int questionNumber;
  final bool? outcome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (outcome) {
      true => AppColors.correct,
      false => AppColors.wrong,
      null => scheme.surface,
    };
    final textColor = switch (outcome) {
      true => AppColors.onPrimary,
      false => AppColors.onPrimary,
      null => scheme.onSurfaceVariant,
    };

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '$questionNumber',
        style: AppTextStyles.caption().copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
