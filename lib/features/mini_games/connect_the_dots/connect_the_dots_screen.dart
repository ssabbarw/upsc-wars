import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../shared/game_intro_view.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'connect_the_dots_controller.dart';

class ConnectTheDotsScreen extends HookConsumerWidget {
  const ConnectTheDotsScreen({
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
    final provider = connectTheDotsControllerProvider(
      (subjects: subjectsCsv, difficulties: difficultiesCsv),
    );
    final async = ref.watch(provider);
    useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.connectTheDots,
        icon: Icons.hub_rounded,
        accent: GameAccent.connectTheDots.accent,
        badgeBg: GameAccent.connectTheDots.badgeBg,
        title: 'Connect the Dots',
        steps: const [
          'Read all three clues together.',
          'Think about what links them.',
          'Tap the option that ties them together.',
        ],
      ),
    );

    final snapshot = async.asData?.value;
    final item = snapshot?.current;
    final revealed = snapshot?.revealed ?? false;
    final complete = snapshot?.sessionComplete ?? false;

    return RgGameScaffold(
      title: 'Connect the Dots',
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
          final picked = state.selectedIndex;
          final pickedWrong =
              revealed && picked != null && picked != item.answerIndex;

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              RgMonoLabel(
                '${item.subject} · ${state.index + 1} of '
                '${state.session.length}',
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < item.dots.length; i++) ...[
                if (i > 0) _Connector(revealed: revealed),
                _ClueCard(text: item.dots[i], revealed: revealed),
              ],
              const SizedBox(height: 12),
              const RgMonoLabel("What's the hidden link?"),
              const SizedBox(height: 8),
              if (!revealed)
                for (var i = 0; i < item.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _OptionPill(
                      label: item.options[i],
                      onTap: () => ref.read(provider.notifier).select(i),
                    ),
                  )
              else ...[
                if (pickedWrong)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _OptionPill(
                      label: item.options[picked],
                      onTap: null,
                      fill: RgColors.wrongBg,
                      borderColor: RgColors.wrong,
                      foreground: RgColors.wrongText,
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                _OptionPill(
                  label: item.options[item.answerIndex],
                  onTap: null,
                  fill: RgColors.correctBg,
                  borderColor: RgColors.teal,
                  foreground: RgColors.tealDeep,
                  borderWidth: 2,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 10),
                RgExplanationChip(text: item.explanation),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ClueCard extends StatelessWidget {
  const _ClueCard({required this.text, required this.revealed});

  final String text;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: revealed ? RgColors.correctBg : RgColors.card,
        borderRadius: BorderRadius.circular(RgRadius.md),
        border: Border.all(
          color: revealed ? RgColors.correctBorder : RgColors.border,
        ),
      ),
      child: Text(
        text,
        style: RgText.body(size: 12, weight: FontWeight.w600),
      ),
    );
  }
}

/// Short vertical tick that threads the clue cards together.
class _Connector extends StatelessWidget {
  const _Connector({required this.revealed});

  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 20),
        width: 1.5,
        height: 10,
        color: revealed ? RgColors.teal : RgColors.border12,
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.onTap,
    this.fill = RgColors.card,
    this.borderColor = RgColors.border12,
    this.foreground = RgColors.ink,
    this.borderWidth = 1.5,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color fill;
  final Color borderColor;
  final Color foreground;
  final double borderWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RgRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(RgRadius.pill),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: RgText.body(
                    size: 12.5,
                    weight: icon == null ? FontWeight.w600 : FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
