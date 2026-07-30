import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../shared/game_intro_view.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'fact_or_bluff_controller.dart';

class FactOrBluffScreen extends HookConsumerWidget {
  const FactOrBluffScreen({
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
    final provider = factOrBluffControllerProvider(
      (subjects: subjectsCsv, difficulties: difficultiesCsv),
    );
    final async = ref.watch(provider);
    final secondsAsync = ref.watch(factOrBluffSecondsRemoteProvider);
    final seconds =
        secondsAsync.asData?.value ?? factOrBluffDefaultSeconds;
    final howToReady = useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.factOrBluff,
        icon: Icons.bolt_rounded,
        accent: GameAccent.factOrBluff.accent,
        badgeBg: GameAccent.factOrBluff.badgeBg,
        title: 'Fact or Bluff',
        stepIcons: const [
          Icons.looks_one_rounded,
          Icons.timer_outlined,
          Icons.looks_3_rounded,
        ],
        steps: [
          'Read the statement fast.',
          'You have $seconds seconds on the clock.',
          'Tap FACT or BLUFF before time runs out.',
        ],
      ),
    );
    final hasContent = async.hasValue;

    // Arm the countdown only after how-to is dismissed and content has loaded.
    useEffect(() {
      if (howToReady && hasContent) {
        ref.read(provider.notifier).start();
      }
      return null;
    }, [howToReady, hasContent]);

    final snapshot = async.asData?.value;
    final item = snapshot?.current;
    final complete = snapshot?.sessionComplete ?? false;
    final awaiting = snapshot?.isAwaitingAnswer ?? true;

    return RgGameScaffold(
      title: 'Fact or Bluff',
      trailing: snapshot == null || complete
          ? null
          : _StreakPill(streak: snapshot.streak),
      footer: item == null || complete
          ? null
          : awaiting
              ? _AnswerButtons(
                  onFact: () => ref.read(provider.notifier).answer(true),
                  onBluff: () => ref.read(provider.notifier).answer(false),
                )
              : RgPillButton(
                  label: 'Next →',
                  onPressed: () => ref.read(provider.notifier).next(),
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
          if (item == null) {
            return Center(
              child: Text(
                state.error ?? 'No content',
                style: RgText.body(color: RgColors.muted),
              ),
            );
          }

          final progress = state.progress;
          final urgent = progress < 0.3;
          final secsLeft = state.secondsLeft.ceil().clamp(0, state.durationSeconds);
          final clock =
              '0:${secsLeft.toString().padLeft(2, '0')}';

          return RgCenteredBody(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            children: [
              if (!awaiting) ...[
                Center(child: _VerdictPill(isFact: item.isFact)),
                const SizedBox(height: 6),
                Center(
                  child: RgMonoLabel(
                    switch (state.verdict) {
                      FactOrBluffVerdict.correct => 'You got it',
                      FactOrBluffVerdict.wrong => 'Not this time',
                      FactOrBluffVerdict.timeout => 'Too slow',
                      FactOrBluffVerdict.none => '',
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Opacity(
                opacity: !awaiting && !item.isFact ? 0.55 : 1,
                child: Text(
                  '“${item.statement}”',
                  textAlign: TextAlign.center,
                  style: RgText.display(
                    size: 20,
                    weight: FontWeight.w800,
                    height: 1.3,
                  ).copyWith(
                    decoration: !awaiting && !item.isFact
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (awaiting) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(RgRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: RgColors.neutralFill,
                    color: urgent ? RgColors.wrong : RgColors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  clock,
                  textAlign: TextAlign.center,
                  style: RgText.mono(
                    size: 22,
                    color: urgent ? RgColors.wrong : RgColors.teal,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                RgExplanationChip(text: item.explanation, size: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: RgColors.warningBg,
        borderRadius: BorderRadius.circular(RgRadius.pill),
      ),
      child: Text(
        'STREAK $streak',
        style: RgText.mono(size: 10, color: RgColors.warningText),
      ),
    );
  }
}

/// Reveals the truth behind the statement — teal for FACT, red for BLUFF.
class _VerdictPill extends StatelessWidget {
  const _VerdictPill({required this.isFact});

  final bool isFact;

  @override
  Widget build(BuildContext context) {
    final bg = isFact ? RgColors.correctBg : RgColors.wrongBg;
    final fg = isFact ? RgColors.tealDeep : RgColors.wrongText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RgRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFact ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            isFact ? 'FACT' : 'BLUFF',
            style: RgText.mono(size: 12, letterSpacingEm: 0.05, color: fg),
          ),
        ],
      ),
    );
  }
}

class _AnswerButtons extends StatelessWidget {
  const _AnswerButtons({required this.onFact, required this.onBluff});

  final VoidCallback onFact;
  final VoidCallback onBluff;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnswerButton(
            label: 'FACT',
            fill: RgColors.teal,
            foreground: RgColors.onDark,
            onTap: onFact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnswerButton(
            label: 'BLUFF',
            fill: RgColors.card,
            foreground: RgColors.ink,
            border: RgColors.ink,
            onTap: onBluff,
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.fill,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  final String label;
  final Color fill;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RgRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(RgRadius.lg),
            border: border == null
                ? null
                : Border.all(color: border!, width: 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: RgText.body(
              size: 14,
              weight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
