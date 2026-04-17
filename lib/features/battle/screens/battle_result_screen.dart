import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import 'package:upsc_wars/features/battle/widgets/battle_question_score_grid.dart';

class BattleResultScreen extends StatelessWidget {
  const BattleResultScreen({super.key, required this.payload});

  final BattleResultPayload payload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = _resultMessage(
      mine: payload.playerScore,
      other: payload.opponentScore,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Battle Result')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message.$1,
              style: AppTextStyles.h1().copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message.$2,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            BattleQuestionScoreGrid(
              playerName: payload.playerName,
              opponentName: payload.opponentName,
              playerOutcomeByQuestion: payload.playerOutcomeByQuestion,
              opponentOutcomeByQuestion: payload.opponentOutcomeByQuestion,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ScoreRow(
              label: payload.playerName,
              score: payload.playerScore.toStringAsFixed(2),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ScoreRow(
              label: payload.opponentName,
              score: payload.opponentScore.toStringAsFixed(2),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _resultMessage({
    required double mine,
    required double other,
  }) {
    if ((mine - other).abs() < 0.001) {
      return ('Neck and neck!', 'It is a tie. That was intense.');
    }
    if (mine > other) {
      return ('Victory unlocked!', 'You outplayed your opponent this round.');
    }
    return ('So close!', 'You lost this one. Come back stronger.');
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.score});
  final String label;
  final String score;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
        ),
        Text(
          score,
          style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}
