import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/screen_flow_analytics.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/battle_result_live_payload.dart';
import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';
import 'package:upsc_wars/features/battle/domain/battle_opponent_policy.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import 'package:upsc_wars/features/battle/providers/battle_session_provider.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';
import 'package:upsc_wars/features/battle/widgets/battle_chat_fab.dart';
import 'package:upsc_wars/features/battle/widgets/battle_live_scoreboard.dart';
import 'package:upsc_wars/features/battle/widgets/battle_result_score_breakdown.dart';
import 'package:upsc_wars/features/battle/widgets/battle_spectate_overlay.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

Future<void> _leaveBattleResultScreen(
  BuildContext context,
  WidgetRef ref,
) async {
  ScreenFlow.logAction(
    ref,
    screenName: ScreenFlow.battleResults,
    actionId: 'leave_to_home',
    actionKind: 'back',
  );
  if (!context.mounted) return;
  // Always home: stack is usually battle test → results; pop would reopen the test.
  context.go('/');
}

(String, String) _battleResultHeadline({
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

class BattleResultScreen extends HookConsumerWidget {
  const BattleResultScreen({super.key, required this.payload});

  final BattleResultPayload payload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spectate = ref.watch(battleSpectateProvider);
    final battleUi = ref.watch(battleSessionProvider(payload.sessionId));
    final battle = battleUi.battleSession;
    final firestoreLive = useState(payload);
    final opponentBattleOver = useState(false);

    final opponentId = battle?.opponent.id;
    final shouldShowChat =
        opponentId != null &&
        opponentId.isNotEmpty &&
        !BattleOpponentPolicy.isBotOpponent(opponentId);
    useEffect(
      () {
        if (!shouldShowChat) return null;
        var disposed = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (disposed || !context.mounted) return;
          ref
              .read(battleChatOverlayProvider.notifier)
              .activate(
                BattleChatOverlayState(
                  opponentEmail: opponentId,
                  opponentName:
                      battle?.opponent.displayName ?? payload.opponentName,
                  opponentPhotoUrl: battle?.opponent.photoUrl,
                ),
              );
        });
        return () {
          disposed = true;
        };
      },
      [
        payload.sessionId,
        shouldShowChat,
        opponentId,
        battle?.opponent.displayName,
        battle?.opponent.photoUrl,
      ],
    );

    useEffect(() {
      if (spectate != null && spectate.sessionId == payload.sessionId) {
        return null;
      }

      var cancelled = false;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      var mergedOpp = <String, String>{};

      firestoreLive.value = payload;
      opponentBattleOver.value = false;

      Future<void> run() async {
        try {
          final load = await ref.read(loadSessionUseCaseProvider.future);
          final base = await load.execute(payload.sessionId);
          if (cancelled) return;

          final user = ref.read(authStateChangesProvider).asData?.value;
          final playerId = (user?.email ?? user?.uid ?? 'player').toLowerCase();
          final questions = base.questions;
          final playerByUuid = battlePlayerResponsesFromActiveSession(base);

          final matchSnap = await BattleFirestorePaths.matchDoc(
            payload.sessionId,
          ).get();
          if (cancelled) return;

          final opponentId = resolveBattleOpponentDocId(
            playerIdLower: playerId,
            matchSnap: matchSnap,
          );

          void applySnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
            if (cancelled) return;
            QueryDocumentSnapshot<Map<String, dynamic>>? oppDoc;
            for (final d in snap.docs) {
              if (d.id == opponentId) {
                oppDoc = d;
                break;
              }
            }
            if (oppDoc == null) return;

            final oppData = oppDoc.data();
            if ((oppData['battle_paper_submitted'] as bool?) == true) {
              opponentBattleOver.value = true;
            }

            final slice = battleOpponentResponsesFromJoinedDoc(
              oppData['responses'],
              questions,
            );
            mergedOpp = {...mergedOpp, ...slice};

            if (mergedOpp.isEmpty) {
              firestoreLive.value = payload;
              return;
            }

            firestoreLive.value = battleResultPayloadFromQuestionMaps(
              seed: payload,
              questions: questions,
              playerByUuid: playerByUuid,
              opponentByUuid: mergedOpp,
            );
          }

          sub = BattleFirestorePaths.joinedUsersCol(
            payload.sessionId,
          ).snapshots().listen(applySnapshot);
        } catch (_) {}
      }

      unawaited(run());
      return () {
        cancelled = true;
        sub?.cancel();
      };
    }, [payload.sessionId, spectate?.sessionId]);

    final displayPayload =
        spectate != null && spectate.sessionId == payload.sessionId
        ? battleResultPayloadFromSpectate(spectate)
        : firestoreLive.value;

    final message = _battleResultHeadline(
      mine: displayPayload.playerScore,
      other: displayPayload.opponentScore,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_leaveBattleResultScreen(context, ref));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battle Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => unawaited(_leaveBattleResultScreen(context, ref)),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BattleLiveScoreboard(
                sessionId: payload.sessionId,
                fallbackPayload: displayPayload,
                battleFinishedOverride:
                    spectate != null &&
                        spectate.sessionId == payload.sessionId
                    ? null
                    : opponentBattleOver.value,
              ),
              const SizedBox(height: AppSpacing.lg),
              BattleResultScoreComparison(payload: displayPayload),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message.$1,
                style: AppTextStyles.h1().copyWith(
                  color: scheme.onSurface,
                ),
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
              if (spectate != null &&
                  spectate.sessionId == payload.sessionId) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  battleSpectateVerdictLine(spectate),
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () async {
                  ScreenFlow.logAction(
                    ref,
                    screenName: ScreenFlow.battleResults,
                    actionId: 'review_explanations',
                  );
                  if (context.mounted) {
                    context.push('/history/${payload.sessionId}');
                  }
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Review explanations'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  if (context.mounted) context.go('/');
                },
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
