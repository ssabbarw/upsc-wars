import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import 'package:upsc_wars/features/battle/providers/battle_session_provider.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';
import 'package:upsc_wars/features/battle/widgets/battle_score_header.dart';

/// Live score strip: prefers Firestore spectate stream after submit, else in-
/// battle [battleSessionProvider], else optional static [fallbackPayload].
class BattleLiveScoreboard extends ConsumerWidget {
  const BattleLiveScoreboard({
    super.key,
    required this.sessionId,
    this.fallbackPayload,
  });

  final String sessionId;
  final BattleResultPayload? fallbackPayload;

  static String _letter(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spectate = ref.watch(battleSpectateProvider);
    if (spectate != null && spectate.sessionId == sessionId) {
      return BattleScoresCollapsible(
        opponentName: spectate.opponentName,
        playerOutcomeByQuestion: spectate.playerOutcomes,
        opponentOutcomeByQuestion: spectate.opponentOutcomes,
        opponentInitial: _letter(spectate.opponentName),
        playerInitial: _letter(spectate.playerName),
        playerPhotoUrl: spectate.playerPhotoUrl,
        initiallyExpanded: true,
      );
    }

    final battle = ref.watch(battleSessionProvider(sessionId)).battleSession;
    if (battle != null) {
      final notifier = ref.read(battleSessionProvider(sessionId).notifier);
      final payload = notifier.buildResultPayload();
      final n = battle.baseSession.questions.length;
      final playerOutcomes =
          payload?.playerOutcomeByQuestion ??
          List<bool?>.filled(n, null);
      final opponentOutcomes =
          payload?.opponentOutcomeByQuestion ??
          List<bool?>.filled(n, null);
      return BattleScoresCollapsible(
        opponentName: battle.opponent.displayName,
        playerOutcomeByQuestion: playerOutcomes,
        opponentOutcomeByQuestion: opponentOutcomes,
        opponentInitial: _letter(battle.opponent.displayName),
        playerInitial: _letter(battle.player.displayName),
        playerPhotoUrl: battle.player.photoUrl,
        initiallyExpanded: true,
      );
    }

    final fb = fallbackPayload;
    if (fb != null && fb.sessionId == sessionId) {
      return BattleScoresCollapsible(
        opponentName: fb.opponentName,
        playerOutcomeByQuestion: fb.playerOutcomeByQuestion,
        opponentOutcomeByQuestion: fb.opponentOutcomeByQuestion,
        opponentInitial: _letter(fb.opponentName),
        playerInitial: _letter(fb.playerName),
        initiallyExpanded: true,
      );
    }

    return const SizedBox.shrink();
  }
}
