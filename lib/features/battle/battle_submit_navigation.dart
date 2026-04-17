import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/providers/battle_session_provider.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';

/// Submit battle, optionally start live spectating, then go to battle results.
Future<void> submitBattleWithOptionalSpectate(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final ui = ref.read(battleSessionProvider(sessionId));
  final battle = ui.battleSession;
  if (battle == null) return;
  if (ui.waitingForGuestToJoin) return;

  final notifier = ref.read(battleSessionProvider(sessionId).notifier);
  final limitSecs = battle.baseSession.timeLimitSecs;
  final deadline =
      limitSecs == null
          ? DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(
            Duration(
              seconds: ((limitSecs - ui.totalElapsedSecs).clamp(0, 86400)),
            ),
          );

  final opponentComplete = battle.baseSession.questions.every(
    (q) => battle.opponentResponsesByQuestion.containsKey(q.uuid),
  );

  final id = await notifier.submit();
  final payload = notifier.buildResultPayload();
  if (!context.mounted) return;

  if (!opponentComplete) {
    final spectate = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Still in play', style: AppTextStyles.h3()),
            content: Text(
              'Your answers are locked in. Your opponent may still be working '
              'through the set. Want a floating live board so you can watch '
              'their progress update?',
              style: AppTextStyles.bodyMd(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No thanks'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keep spectating'),
              ),
            ],
          ),
    );
    if (spectate == true) {
      ref.read(battleSpectateProvider.notifier).start(
            BattleSpectateStartArgs(
              sessionId: battle.id,
              playerId: battle.player.id,
              opponentId: battle.opponent.id,
              playerName: battle.player.displayName,
              opponentName: battle.opponent.displayName,
              playerPhotoUrl: battle.player.photoUrl,
              questions: battle.baseSession.questions,
              playerByUuid: Map<String, String>.from(
                battle.playerResponsesByQuestion,
              ),
              opponentByUuid: Map<String, String>.from(
                battle.opponentResponsesByQuestion,
              ),
              deadline: deadline,
            ),
          );
    }
  }

  if (!context.mounted) return;
  if (payload != null) {
    context.go('/battle-results/$id', extra: payload);
  } else {
    context.go('/battle-results/$id');
  }
}
