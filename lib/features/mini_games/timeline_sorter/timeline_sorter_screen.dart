import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../shared/game_intro_view.dart';
import '../shared/mini_game_models.dart';
import '../shared/revision_game_analytics.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'timeline_sorter_controller.dart';

class TimelineSorterScreen extends HookConsumerWidget {
  const TimelineSorterScreen({
    super.key,
    this.subjectsCsv = '',
    this.difficultiesCsv = '',
    this.initialLang = '',
  });

  /// Comma-separated subject slugs to filter content by; empty = all.
  final String subjectsCsv;

  /// Comma-separated difficulty names to filter content by; empty = all.
  final String difficultiesCsv;

  /// Optional `lang` query param (`en` / `hi`); falls back to saved app language.
  final String initialLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langState = useState(
      normalizeMiniGameLang(
        initialLang.isNotEmpty ? initialLang : watchAppLanguage(ref),
      ),
    );
    final lang = langState.value;
    void onLangChanged(String v) {
      langState.value = v;
      persistAppLanguage(ref, v);
    }

    final provider = timelineSorterControllerProvider(
      (subjects: subjectsCsv, difficulties: difficultiesCsv),
    );
    final async = ref.watch(provider);
    final howToReady = useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.timelineSorter,
        icon: Icons.timeline_rounded,
        accent: GameAccent.timelineSorter.accent,
        badgeBg: GameAccent.timelineSorter.badgeBg,
        title: 'Timeline Sorter',
        steps: const [
          'Read the shuffled events for the set.',
          'Hold and drag rows to place them in order.',
          'Tap Check to reveal years and what you got right.',
        ],
      ),
    );

    final snapshot = async.asData?.value;
    final set = snapshot?.current;
    final revealed = snapshot?.phase == TimelinePhase.revealed;
    final complete = snapshot?.phase == TimelinePhase.sessionComplete;
    final session = snapshot?.session ?? const [];
    useGameScreenOpenedAnalytics(ref, RevisionGameNames.timelineSorter);
    useGameSessionAnalytics(
      ref: ref,
      gameName: RevisionGameNames.timelineSorter,
      readyToStart: howToReady && session.isNotEmpty,
      sessionComplete: complete,
      correctCount: snapshot?.correctCount ?? 0,
      totalRounds: session.length,
      sessionKey: session.isEmpty ? null : session.map((e) => e.id).join(','),
    );

    return RgGameScaffold(
      title: set == null || complete
          ? 'Timeline Sorter'
          : '${set.subject} · Set ${snapshot!.setIndex + 1}/'
              '${snapshot.session.length}',
      trailing: set == null || complete
          ? null
          : RgLangToggle(
              language: lang,
              onChanged: onLangChanged,
              minHeight: 28,
            ),
      footer: set == null || complete
          ? null
          : RgPillButton(
              label: revealed ? 'Next set →' : 'Check',
              verticalPadding: 11,
              onPressed: () => revealed
                  ? ref.read(provider.notifier).nextSet()
                  : ref.read(provider.notifier).check(),
            ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: RgColors.teal),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: RgText.body(color: RgColors.muted)),
        ),
        data: (state) {
          if (complete) {
            return RgSessionCompleteView(
              correct: state.correctCount,
              total: state.session.length,
              onPlayAgain: () => ref.read(provider.notifier).playAgain(),
            );
          }
          if (set == null) {
            return Center(
              child: Text(
                state.error ?? 'No content',
                style: RgText.body(color: RgColors.muted),
              ),
            );
          }
          final correctness = state.slotCorrectness;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: revealed
                    ? _ScoreBanner(
                        correct: state.slotCorrectCount,
                        total: state.order.length,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RgMonoLabel(set.themeForLang(lang)),
                          const SizedBox(height: 4),
                          Text(
                            'Hold and drag to reorder, then check.',
                            style: RgText.body(
                              size: 11,
                              color: RgColors.mutedSoft,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  buildDefaultDragHandles: false,
                  itemCount: state.order.length,
                  onReorderStart:
                      revealed ? null : (_) => HapticFeedback.lightImpact(),
                  onReorder: revealed
                      ? (_, _) {}
                      : (oldIndex, newIndex) => ref
                          .read(provider.notifier)
                          .reorder(oldIndex, newIndex),
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final t = Curves.easeInOut.transform(animation.value);
                        return Material(
                          elevation: 2 + 6 * t,
                          color: RgColors.transparent,
                          borderRadius: BorderRadius.circular(RgRadius.md),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  itemBuilder: (context, slot) {
                    final item = set.items[state.order[slot]];
                    final slotCorrect =
                        slot < correctness.length && correctness[slot];

                    final tile = Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: revealed ? 10 : 11,
                      ),
                      decoration: BoxDecoration(
                        color: !revealed
                            ? RgColors.card
                            : slotCorrect
                                ? RgColors.correctBg
                                : RgColors.wrongBg,
                        borderRadius: BorderRadius.circular(RgRadius.md),
                        border: Border.all(
                          color: !revealed
                              ? RgColors.border
                              : slotCorrect
                                  ? RgColors.correctBorder
                                  : RgColors.wrongBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (revealed)
                            Icon(
                              slotCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 16,
                              color: slotCorrect
                                  ? RgColors.tealDeep
                                  : RgColors.wrongText,
                            )
                          else
                            const Icon(
                              Icons.drag_handle_rounded,
                              size: 16,
                              color: RgColors.dragHandle,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.labelForLang(lang),
                              style: RgText.body(
                                size: 12.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (revealed) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.yearDisplay,
                              style: RgText.mono(
                                size: 11,
                                color: slotCorrect
                                    ? RgColors.tealDeep
                                    : RgColors.wrongText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );

                    return KeyedSubtree(
                      key: ValueKey(state.order[slot]),
                      child: revealed
                          ? tile
                          : ReorderableDelayedDragStartListener(
                              index: slot,
                              child: tile,
                            ),
                    );
                  },
                ),
              ),
              if (revealed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Text(
                    set.explanationForLang(lang),
                    style: RgText.body(
                      size: 11,
                      height: 1.5,
                      color: RgColors.muted,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Amber "4 of 5 correct" strip shown once the set is checked.
class _ScoreBanner extends StatelessWidget {
  const _ScoreBanner({required this.correct, required this.total});

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RgColors.warningBg,
        borderRadius: BorderRadius.circular(RgRadius.sm),
        border: Border.all(color: RgColors.warningBorder),
      ),
      child: Text(
        '$correct of $total correct',
        style: RgText.body(
          size: 12,
          weight: FontWeight.w700,
          color: RgColors.warningText,
        ),
      ),
    );
  }
}
