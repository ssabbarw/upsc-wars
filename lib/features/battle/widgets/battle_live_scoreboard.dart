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
    this.battleFinishedOverride,
  });

  final String sessionId;
  final BattleResultPayload? fallbackPayload;

  /// When non-null, forces the "Battle finished" chip on [BattleScoresCollapsible].
  final bool? battleFinishedOverride;

  static String _letter(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spectate = ref.watch(battleSpectateProvider);
    if (spectate != null && spectate.sessionId == sessionId) {
      final finished = battleFinishedOverride ?? spectate.battleSettled;
      return BattleScoresCollapsible(
        opponentName: spectate.opponentName,
        playerOutcomeByQuestion: spectate.playerOutcomes,
        opponentOutcomeByQuestion: spectate.opponentOutcomes,
        opponentInitial: _letter(spectate.opponentName),
        playerInitial: _letter(spectate.playerName),
        playerPhotoUrl: spectate.playerPhotoUrl,
        initiallyExpanded: true,
        battleFinished: finished,
      );
    }

    final ui = ref.watch(battleSessionProvider(sessionId));
    final battle = ui.battleSession;
    if (battle != null) {
      final notifier = ref.read(battleSessionProvider(sessionId).notifier);
      final payload = notifier.buildResultPayload();
      final n = battle.baseSession.questions.length;
      final playerOutcomes =
          payload?.playerOutcomeByQuestion ?? List<bool?>.filled(n, null);
      final opponentOutcomes =
          payload?.opponentOutcomeByQuestion ?? List<bool?>.filled(n, null);
      final opponentCaughtUp = battle.baseSession.questions.every(
        (q) => battle.opponentResponsesByQuestion.containsKey(q.uuid),
      );
      final finished =
          battleFinishedOverride ??
          (ui.opponentPaperSubmitted || opponentCaughtUp);
      return BattleScoresCollapsible(
        opponentName: battle.opponent.displayName,
        playerOutcomeByQuestion: playerOutcomes,
        opponentOutcomeByQuestion: opponentOutcomes,
        opponentInitial: _letter(battle.opponent.displayName),
        playerInitial: _letter(battle.player.displayName),
        playerPhotoUrl: battle.player.photoUrl,
        initiallyExpanded: true,
        battleFinished: finished,
      );
    }

    final fb = fallbackPayload;
    if (fb != null && fb.sessionId == sessionId) {
      final finished = battleFinishedOverride ?? false;
      return BattleScoresCollapsible(
        opponentName: fb.opponentName,
        playerOutcomeByQuestion: fb.playerOutcomeByQuestion,
        opponentOutcomeByQuestion: fb.opponentOutcomeByQuestion,
        opponentInitial: _letter(fb.opponentName),
        playerInitial: _letter(fb.playerName),
        initiallyExpanded: true,
        battleFinished: finished,
      );
    }

    return const SizedBox.shrink();
  }
}
