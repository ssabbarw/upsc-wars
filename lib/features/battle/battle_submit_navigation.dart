import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/providers/battle_session_provider.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';

enum _BattleSubmitChoice {
  /// Stay on the battle test (dismiss sheet only).
  continueBattle,

  /// Lock in answers, show live board while opponent catches up, then results.
  watchAndExit,

  /// Lock in answers and go to results without the live board.
  submitOnly,
}

/// Submit battle, optionally start live spectating, then go to battle results.
///
/// When [askConfirmation] is true (default), a bottom sheet asks how to finish.
/// Timer-driven submits pass `askConfirmation: false` and behave like **Submit only**.
Future<void> submitBattleWithOptionalSpectate(
  BuildContext context,
  WidgetRef ref,
  String sessionId, {
  bool askConfirmation = true,
}) async {
  final ui = ref.read(battleSessionProvider(sessionId));
  final battle = ui.battleSession;
  if (battle == null) return;
  if (ui.waitingForGuestToJoin) return;

  final notifier = ref.read(battleSessionProvider(sessionId).notifier);
  final limitSecs = battle.baseSession.timeLimitSecs;
  final deadline = limitSecs == null
      ? DateTime.now().add(const Duration(days: 1))
      : DateTime.now().add(
          Duration(
            seconds: ((limitSecs - ui.totalElapsedSecs).clamp(0, 86400)),
          ),
        );

  final opponentComplete = battle.baseSession.questions.every(
    (q) => battle.opponentResponsesByQuestion.containsKey(q.uuid),
  );

  var wantSpectate = false;
  if (askConfirmation) {
    final choice = await _showBattleSubmitConfirmationSheet(
      context,
      opponentStillPlaying: !opponentComplete,
    );
    if (!context.mounted) return;
    if (choice == null || choice == _BattleSubmitChoice.continueBattle) {
      return;
    }
    wantSpectate = choice == _BattleSubmitChoice.watchAndExit;
  }

  final id = await notifier.submit();
  final payload = notifier.buildResultPayload();
  if (!context.mounted) return;

  if (wantSpectate) {
    ref
        .read(battleSpectateProvider.notifier)
        .start(
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

  if (!context.mounted) return;
  if (payload != null) {
    context.push('/battle-results/$id', extra: payload);
  } else {
    context.push('/battle-results/$id');
  }
}

Future<_BattleSubmitChoice?> _showBattleSubmitConfirmationSheet(
  BuildContext context, {
  required bool opponentStillPlaying,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<_BattleSubmitChoice>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
          top: AppSpacing.sm,
        ),
        child: Material(
          color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
          elevation: 2,
          shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.35 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(
              color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Submit your answers?',
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  opponentStillPlaying
                      ? 'Your score will lock in. You can watch your opponent '
                            'finish on a live board, or go straight to results.'
                      : 'Your score will lock in and you will see the outcome.',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _BattleSubmitChoice.continueBattle),
                  child: const Text('Continue battle'),
                ),
                if (opponentStillPlaying) ...[
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(ctx, _BattleSubmitChoice.watchAndExit),
                    child: const Text('Watch their progress'),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _BattleSubmitChoice.submitOnly),
                  child: const Text('Submit & see results'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
