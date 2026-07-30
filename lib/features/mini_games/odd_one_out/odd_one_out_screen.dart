import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../shared/game_intro_view.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'odd_one_out_controller.dart';

class OddOneOutScreen extends HookConsumerWidget {
  const OddOneOutScreen({
    super.key,
    this.subjectsCsv = '',
    this.difficultiesCsv = '',
  });

  /// Comma-separated subject slugs to filter content by; empty = all.
  final String subjectsCsv;

  /// Comma-separated difficulty names to filter content by; empty = all.
  final String difficultiesCsv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = oddOneOutControllerProvider(
      (subjects: subjectsCsv, difficulties: difficultiesCsv),
    );
    final async = ref.watch(provider);
    useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.oddOneOut,
        icon: Icons.rule_rounded,
        accent: GameAccent.oddOneOut.accent,
        badgeBg: GameAccent.oddOneOut.badgeBg,
        title: 'Odd One Out',
        steps: const [
          'Look at all four options.',
          "Tap the one that doesn't belong.",
          'See the highlight and explanation instantly.',
        ],
      ),
    );

    final snapshot = async.asData?.value;
    final item = snapshot?.current;
    final revealed = snapshot?.revealed ?? false;
    final complete = snapshot?.sessionComplete ?? false;

    return RgGameScaffold(
      title: item == null || complete
          ? 'Odd One Out'
          : 'Odd One Out · ${item.subject}',
      footer: revealed && !complete
          ? RgPillButton(
              label: 'Next →',
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
                state.error ?? 'No content',
                style: RgText.body(color: RgColors.muted),
              ),
            );
          }

          return RgCenteredBody(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
            children: [
              Center(
                child: RgMonoLabel(
                  '${state.index + 1} of ${state.session.length}',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Which one doesn't belong?",
                textAlign: TextAlign.center,
                style: RgText.display(size: 16),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: item.items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, i) {
                  final selected = state.selectedIndex == i;
                  final isOdd = i == item.oddIndex;
                  return _OddTile(
                    label: item.items[i],
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
                RgExplanationChip(text: item.explanation),
              ],
            ],
          );
        },
      ),
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
