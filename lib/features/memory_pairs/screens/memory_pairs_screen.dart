import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/memory_pair_sets_data.dart';
import '../domain/memory_pair_models.dart';
import '../providers/memory_pairs_providers.dart';
import '../widgets/memory_pair_game_view.dart';
import '../widgets/memory_pair_result_view.dart';
import '../widgets/memory_pair_revise_view.dart';
import '../widgets/memory_pair_set_detail_view.dart';
import '../widgets/memory_pairs_sets_view.dart';

enum _MemoryPairsStep { list, detail, revise, game, result }

class MemoryPairsScreen extends HookConsumerWidget {
  const MemoryPairsScreen({super.key, this.initialSetId});

  final String? initialSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = watchAppLanguage(ref);
    final step = useState(_MemoryPairsStep.list);
    final activeSet = useState<MemoryPairSetDefinition?>(null);
    final difficulty = useState(MemoryPairDifficulty.medium);
    final lastResult = useState<MemoryPairGameResult?>(null);
    final isNewBest = useState(false);
    final retryPairs = useState<List<MemoryPair>?>(null);
    final isWeakRetry = useState(false);

    useEffect(() {
      final id = initialSetId;
      if (id == null) return null;
      final set = memoryPairSetById(id);
      if (set != null && set.hasPlayablePairs) {
        activeSet.value = set;
        step.value = _MemoryPairsStep.detail;
      }
      return null;
    }, [initialSetId]);

    useEffect(() {
      Future(() async {
        final prefs = await ref.read(prefsServiceProvider.future);
        if (prefs.memoryPairsGameDiscovered) return;
        prefs.memoryPairsGameDiscovered = true;
        ref.invalidate(prefsServiceProvider);
        await Analytics.track(ref, const MemoryPairsGameDiscoveredEvent());
      });
      return null;
    }, const []);

    Future<bool> saveResult(MemoryPairGameResult result) async {
      final set = activeSet.value;
      if (set == null) return false;
      final repo = await ref.read(memoryPairStatsRepositoryProvider.future);
      final wasBest = await repo.recordResult(
        setId: set.id,
        difficulty: difficulty.value,
        result: result,
      );
      ref.invalidate(memoryPairSetListProvider);
      ref.invalidate(memoryPairSetStatsProvider((set.id, difficulty.value)));
      return wasBest;
    }

    void openSet(MemoryPairSetDefinition set) {
      activeSet.value = set;
      step.value = _MemoryPairsStep.detail;
    }

    void startGame({List<MemoryPair>? pairsOverride}) {
      retryPairs.value = pairsOverride;
      isWeakRetry.value = pairsOverride != null;
      final set = activeSet.value;
      if (set != null) {
        unawaited(() async {
          final prefs = await ref.read(prefsServiceProvider.future);
          if (prefs.memoryPairsGamePlayed) return;
          prefs.memoryPairsGamePlayed = true;
          ref.invalidate(prefsServiceProvider);
          await Analytics.track(
            ref,
            MemoryPairsGamePlayedEvent(
              setId: set.id,
              difficulty: difficulty.value.id,
            ),
          );
        }());
      }
      step.value = _MemoryPairsStep.game;
    }

    void onGameDone(MemoryPairGameResult result) async {
      lastResult.value = result;
      isNewBest.value = isWeakRetry.value
          ? false
          : await saveResult(result);
      isWeakRetry.value = false;
      if (!context.mounted) return;
      step.value = _MemoryPairsStep.result;
    }

    String title() => switch (step.value) {
          _MemoryPairsStep.list => 'Revision Games',
          _MemoryPairsStep.detail => 'Set detail',
          _MemoryPairsStep.revise => 'Revise',
          _MemoryPairsStep.game =>
            activeSet.value?.nameForLang(lang) ?? 'Memory Pairs',
          _MemoryPairsStep.result => 'Summary',
        };

    void onBack() {
      switch (step.value) {
        case _MemoryPairsStep.list:
          context.pop();
        case _MemoryPairsStep.detail:
          step.value = _MemoryPairsStep.list;
        case _MemoryPairsStep.revise:
          step.value = _MemoryPairsStep.detail;
        case _MemoryPairsStep.game:
          step.value = _MemoryPairsStep.detail;
          retryPairs.value = null;
        case _MemoryPairsStep.result:
          step.value = _MemoryPairsStep.list;
          activeSet.value = null;
          retryPairs.value = null;
      }
    }

    final set = activeSet.value;
    final pairsForGame = () {
      if (set == null) return <MemoryPair>[];
      if (retryPairs.value != null) return retryPairs.value!;
      return set.pairs.take(difficulty.value.pairCount).toList();
    }();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      title(),
                      style: AppTextStyles.h2().copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (step.value) {
                _MemoryPairsStep.list => MemoryPairsSetsView(onOpenSet: openSet),
                _MemoryPairsStep.detail when set != null => MemoryPairSetDetailView(
                    set: set,
                    lang: lang,
                    onRevise: (d) {
                      difficulty.value = d;
                      step.value = _MemoryPairsStep.revise;
                    },
                    onPlay: (d) {
                      difficulty.value = d;
                      startGame();
                    },
                  ),
                _MemoryPairsStep.revise when set != null => MemoryPairReviseView(
                    set: set,
                    difficulty: difficulty.value,
                    lang: lang,
                    onPlay: () => startGame(),
                  ),
                _MemoryPairsStep.game when set != null => MemoryPairGameView(
                    pairs: pairsForGame,
                    lang: lang,
                    onDone: onGameDone,
                    onQuit: () {
                      step.value = _MemoryPairsStep.detail;
                      retryPairs.value = null;
                    },
                  ),
                _MemoryPairsStep.result when set != null &&
                    lastResult.value != null =>
                  MemoryPairResultView(
                    set: set,
                    difficulty: difficulty.value,
                    lang: lang,
                    result: lastResult.value!,
                    isNewBest: isNewBest.value,
                    onTryAnotherSet: () {
                      step.value = _MemoryPairsStep.list;
                      activeSet.value = null;
                    },
                    onPlayAgain: () => startGame(),
                    onExit: () {
                      step.value = _MemoryPairsStep.list;
                      activeSet.value = null;
                    },
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
