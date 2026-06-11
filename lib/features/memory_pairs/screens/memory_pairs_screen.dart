import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/memory_pair_sets_data.dart';
import '../domain/memory_pair_catalog_grouping.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_subject_meta.dart';
import '../providers/memory_pairs_providers.dart';
import '../widgets/memory_pair_shared_widgets.dart';
import '../widgets/memory_pair_game_view.dart';
import '../widgets/memory_pair_result_view.dart';
import '../widgets/memory_pair_revise_view.dart';
import '../widgets/memory_pair_set_detail_view.dart';
import '../widgets/memory_pairs_sets_view.dart';
import '../widgets/memory_pairs_subject_view.dart';

enum _MemoryPairsStep { subjects, subject, setDetail, revise, game, result }

class MemoryPairsScreen extends HookConsumerWidget {
  const MemoryPairsScreen({
    super.key,
    this.initialSetId,
    this.autoplay = false,
  });

  final String? initialSetId;

  /// When true (push welcome → Start), opens the match board immediately.
  final bool autoplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = watchAppLanguage(ref);
    final step = useState(_MemoryPairsStep.subjects);
    final activeSubject = useState<MemoryPairSubjectGroup?>(null);
    final activeSet = useState<MemoryPairSetDefinition?>(null);
    final lastResult = useState<MemoryPairGameResult?>(null);
    final isNewBest = useState(false);
    final retryPairs = useState<List<MemoryPair>?>(null);
    final isWeakRetry = useState(false);

    useEffect(() {
      final id = initialSetId;
      if (id == null) return null;
      final set = memoryPairSetById(id);
      if (set == null || !set.hasPlayablePairs) return null;

      Future(() async {
        final items = await ref.read(memoryPairSetListProvider.future);
        final groups = groupMemoryPairSetsBySubject(items, lang: lang);
        MemoryPairSubjectGroup? group;
        for (final g in groups) {
          if (g.sortedItems.any((i) => i.definition.id == id)) {
            group = g;
            break;
          }
        }
        activeSubject.value = group;
        activeSet.value = set;
        step.value = autoplay
            ? _MemoryPairsStep.game
            : _MemoryPairsStep.setDetail;
        if (autoplay) {
          unawaited(() async {
            final prefs = await ref.read(prefsServiceProvider.future);
            final isFirstEver = !prefs.memoryPairsGamePlayed;
            unawaited(
              AdminDashboardWriterService().recordMemoryGamePlay(
                isFirstEverOnDevice: isFirstEver,
              ),
            );
            if (prefs.memoryPairsGamePlayed) return;
            prefs.memoryPairsGamePlayed = true;
            ref.invalidate(prefsServiceProvider);
            await Analytics.track(
              ref,
              MemoryPairsGamePlayedEvent(
                setId: set.id,
                difficulty: set.difficulty.id,
              ),
            );
          }());
        }
      });
      return null;
    }, [initialSetId, lang, autoplay]);

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
        difficulty: set.difficulty,
        result: result,
      );
      ref.invalidate(memoryPairSetListProvider);
      ref.invalidate(memoryPairSetStatsProvider((set.id, set.difficulty)));
      return wasBest;
    }

    void openSubject(MemoryPairSubjectGroup group) {
      activeSubject.value = group;
      step.value = _MemoryPairsStep.subject;
    }

    void openSet(MemoryPairSetDefinition set) {
      activeSet.value = set;
      step.value = _MemoryPairsStep.setDetail;
    }

    void startGame({List<MemoryPair>? pairsOverride}) {
      retryPairs.value = pairsOverride;
      isWeakRetry.value = pairsOverride != null;
      final set = activeSet.value;
      if (set != null) {
        unawaited(() async {
          final prefs = await ref.read(prefsServiceProvider.future);
          final isFirstEver = !prefs.memoryPairsGamePlayed;
          unawaited(
            AdminDashboardWriterService().recordMemoryGamePlay(
              isFirstEverOnDevice: isFirstEver,
            ),
          );
          if (prefs.memoryPairsGamePlayed) return;
          prefs.memoryPairsGamePlayed = true;
          ref.invalidate(prefsServiceProvider);
          await Analytics.track(
            ref,
            MemoryPairsGamePlayedEvent(
              setId: set.id,
              difficulty: set.difficulty.id,
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
          _MemoryPairsStep.subjects => 'Memory Pairs',
          _MemoryPairsStep.subject =>
            activeSubject.value?.subjectLabel ?? 'Subject',
          _MemoryPairsStep.setDetail => 'Set detail',
          _MemoryPairsStep.revise => 'Revise',
          _MemoryPairsStep.game =>
            activeSet.value?.nameForLang(lang) ?? 'Memory Pairs',
          _MemoryPairsStep.result => 'Summary',
        };

    void exitToHomeOrPop() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }

    void onBack() {
      switch (step.value) {
        case _MemoryPairsStep.subject:
          step.value = _MemoryPairsStep.subjects;
          activeSubject.value = null;
          return;
        case _MemoryPairsStep.setDetail:
          step.value = _MemoryPairsStep.subject;
          activeSet.value = null;
          return;
        case _MemoryPairsStep.revise:
          step.value = _MemoryPairsStep.setDetail;
          return;
        case _MemoryPairsStep.game:
          step.value = _MemoryPairsStep.setDetail;
          retryPairs.value = null;
          return;
        case _MemoryPairsStep.result:
          step.value = _MemoryPairsStep.subjects;
          activeSet.value = null;
          activeSubject.value = null;
          retryPairs.value = null;
          return;
        case _MemoryPairsStep.subjects:
          exitToHomeOrPop();
          return;
      }
    }

    final set = activeSet.value;
    final subject = activeSubject.value;
    final pairsForGame = () {
      if (set == null) return <MemoryPair>[];
      if (retryPairs.value != null) return retryPairs.value!;
      return set.pairs.take(set.difficulty.pairCount).toList();
    }();

    final showAppBarTitle = step.value != _MemoryPairsStep.subjects;
    final atCatalog = step.value == _MemoryPairsStep.subjects;
    final canLeaveRoute = atCatalog && context.canPop();

    return PopScope(
      canPop: canLeaveRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
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
                  if (showAppBarTitle)
                    Expanded(
                      child: Text(
                        title(),
                        style: AppTextStyles.h2().copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: step.value == _MemoryPairsStep.subject
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  if (step.value == _MemoryPairsStep.subject && subject != null)
                    MemoryPairSubjectIcon(
                      icon: memoryPairSubjectVisual(subject.subjectKey).icon,
                      color: memoryPairSubjectVisual(subject.subjectKey).accent,
                      size: 40,
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (step.value) {
                _MemoryPairsStep.subjects => MemoryPairsSetsView(
                    onOpenSubject: openSubject,
                  ),
                _MemoryPairsStep.subject when subject != null =>
                  MemoryPairsSubjectView(
                    group: subject,
                    lang: lang,
                    onOpenSet: openSet,
                  ),
                _MemoryPairsStep.setDetail when set != null =>
                  MemoryPairSetDetailView(
                    set: set,
                    lang: lang,
                    onRevise: () => step.value = _MemoryPairsStep.revise,
                    onPlay: startGame,
                  ),
                _MemoryPairsStep.revise when set != null => MemoryPairReviseView(
                    set: set,
                    difficulty: set.difficulty,
                    lang: lang,
                    onPlay: () => startGame(),
                  ),
                _MemoryPairsStep.game when set != null => MemoryPairGameView(
                    pairs: pairsForGame,
                    lang: lang,
                    onDone: onGameDone,
                    onQuit: () {
                      step.value = _MemoryPairsStep.setDetail;
                      retryPairs.value = null;
                    },
                  ),
                _MemoryPairsStep.result when set != null &&
                    lastResult.value != null =>
                  MemoryPairResultView(
                    set: set,
                    difficulty: set.difficulty,
                    lang: lang,
                    result: lastResult.value!,
                    isNewBest: isNewBest.value,
                    onTryAnotherSet: () {
                      step.value = _MemoryPairsStep.subjects;
                      activeSet.value = null;
                      activeSubject.value = null;
                    },
                    onPlayAgain: () => startGame(),
                    onExit: () {
                      step.value = _MemoryPairsStep.subjects;
                      activeSet.value = null;
                      activeSubject.value = null;
                    },
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}
