import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import 'package:upsc_wars/features/battle/widgets/battle_score_header.dart';

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
    String letter(String name) {
      final t = name.trim();
      if (t.isEmpty) return '?';
      return t[0].toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Battle Result')),
      body: SingleChildScrollView(
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
            BattleScoresCollapsible(
              opponentName: payload.opponentName,
              playerOutcomeByQuestion: payload.playerOutcomeByQuestion,
              opponentOutcomeByQuestion: payload.opponentOutcomeByQuestion,
              opponentInitial: letter(payload.opponentName),
              playerInitial: letter(payload.playerName),
              initiallyExpanded: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed:
                  () => context.push('/history/${payload.sessionId}'),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Review explanations'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
            const SizedBox(height: AppSpacing.lg),
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
