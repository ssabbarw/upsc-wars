import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../shared/game_intro_view.dart';
import '../shared/mini_game_models.dart';
import '../shared/revision_game_analytics.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'odd_one_out_controller.dart';
import '../../../l10n/l10n.dart';

class OddOneOutScreen extends HookConsumerWidget {
  const OddOneOutScreen({
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

    final provider = oddOneOutControllerProvider((
      subjects: subjectsCsv,
      difficulties: difficultiesCsv,
    ));
    final async = ref.watch(provider);
    final howToReady = useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.oddOneOut,
        icon: Icons.rule_rounded,
        accent: GameAccent.oddOneOut.accent,
        badgeBg: GameAccent.oddOneOut.badgeBg,
        title: 'Odd One Out',
        steps: [
          context.l10n.gmOddStep1,
          context.l10n.gmOddStep2,
          context.l10n.gmOddStep3,
        ],
      ),
    );

    final snapshot = async.asData?.value;
    final item = snapshot?.current;
    final revealed = snapshot?.revealed ?? false;
    final complete = snapshot?.sessionComplete ?? false;
    final session = snapshot?.session ?? const [];
    useGameScreenOpenedAnalytics(ref, RevisionGameNames.oddOneOut);
    useGameSessionAnalytics(
      ref: ref,
      gameName: RevisionGameNames.oddOneOut,
      readyToStart: howToReady && session.isNotEmpty,
      sessionComplete: complete,
      correctCount: snapshot?.correctCount ?? 0,
      totalRounds: session.length,
      sessionKey: session.isEmpty ? null : session.map((e) => e.id).join(','),
    );

    return RgGameScaffold(
      title: item == null || complete
          ? 'Odd One Out'
          : context.l10n.gmOddTitle(item.subject),
      trailing: item == null || complete
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgLangToggle(
                  language: lang,
                  onChanged: onLangChanged,
                  minHeight: 28,
                ),
                const SizedBox(width: 8),
                _DifficultyPill(difficulty: item.difficulty),
              ],
            ),
      footer: revealed && !complete
          ? RgPillButton(
              label: context.l10n.gmNext,
              verticalPadding: 11,
              onPressed: () => ref.read(provider.notifier).next(),
            )
          : null,
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
          if (item == null) {
            return Center(
              child: Text(
                state.error ?? context.l10n.gmNoContent,
                style: RgText.body(color: RgColors.muted),
              ),
            );
          }

          return RgCenteredBody(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
            children: [
              Center(
                child: RgMonoLabel(
                  context.l10n.gmNOfTotal(
                    state.index + 1,
                    state.session.length,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lang == 'hi' ? 'विषम को चुनें' : 'Pick the odd one out',
                textAlign: TextAlign.center,
                style: RgText.display(size: 16),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: item.itemsForLang(lang).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, i) {
                  final selected = state.selectedIndex == i;
                  final isOdd = i == item.oddIndex;
                  return _OddTile(
                    label: item.itemsForLang(lang)[i],
                    revealed: revealed,
                    isAnswer: isOdd,
                    isWrongPick: selected && !isOdd,
                    onTap: revealed
                        ? null
                        : () => ref.read(provider.notifier).select(i),
                  );
                },
              ),
              if (revealed) ...[
                const SizedBox(height: 16),
                RgExplanationChip(text: item.explanationForLang(lang)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({required this.difficulty});

  final MiniGameDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (difficulty) {
      MiniGameDifficulty.easy => (
        'EASY',
        RgColors.tealDeep,
        RgColors.correctBg,
      ),
      MiniGameDifficulty.medium => (
        'MEDIUM',
        RgColors.warningText,
        RgColors.warningBg,
      ),
      MiniGameDifficulty.hard => ('HARD', RgColors.wrongText, RgColors.wrongBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RgRadius.pill),
      ),
      child: Text(label, style: RgText.mono(size: 10, color: fg)),
    );
  }
}

class _OddTile extends StatelessWidget {
  const _OddTile({
    required this.label,
    required this.revealed,
    required this.isAnswer,
    required this.isWrongPick,
    required this.onTap,
  });

  final String label;
  final bool revealed;
  final bool isAnswer;
  final bool isWrongPick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    var bg = RgColors.card;
    var borderColor = RgColors.border12;
    var textColor = RgColors.ink;
    var borderWidth = 1.5;
    IconData? corner;
    var cornerColor = RgColors.tealDeep;

    if (revealed && isAnswer) {
      bg = RgColors.correctBg;
      borderColor = RgColors.teal;
      textColor = RgColors.tealDeep;
      borderWidth = 2;
      corner = Icons.check_circle_rounded;
    } else if (revealed && isWrongPick) {
      bg = RgColors.wrongBg;
      borderColor = RgColors.wrong;
      textColor = RgColors.wrongText;
      corner = Icons.cancel_rounded;
      cornerColor = RgColors.wrongText;
    }

    Widget tile = Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RgRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(RgRadius.lg),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: RgText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              if (corner != null)
                Positioned(
                  top: 6,
                  right: 8,
                  child: Icon(corner, size: 14, color: cornerColor),
                ),
            ],
          ),
        ),
      ),
    );

    if (revealed && !isAnswer && !isWrongPick) {
      tile = Opacity(opacity: 0.5, child: tile);
    }
    return tile;
  }
}
