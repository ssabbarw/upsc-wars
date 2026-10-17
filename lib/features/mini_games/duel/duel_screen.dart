import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../shared/game_intro_view.dart';
import '../shared/mini_game_models.dart';
import '../shared/revision_game_analytics.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'duel_controller.dart';

/// 1v1 Duel — Revision Games v2 "scoreboard-strip" treatment (option 1a).
///
/// Two mirrored halves (Player 2 rotated 180°) split by a solid teal seam that
/// carries the running score. Each player locks a choice (or passes) without
/// revealing correctness; right/wrong colours appear only after both have
/// answered. The match ends on a stamped victory/defeat screen.
class DuelScreen extends HookConsumerWidget {
  const DuelScreen({
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
    final sharedInitial = normalizeMiniGameLang(
      initialLang.isNotEmpty ? initialLang : watchAppLanguage(ref),
    );
    // Each player can pick EN/HI independently for their half.
    final p1LangState = useState(sharedInitial);
    final p2LangState = useState(sharedInitial);
    final p1Lang = p1LangState.value;
    final p2Lang = p2LangState.value;

    final provider = duelControllerProvider((
      subjects: subjectsCsv,
      difficulties: difficultiesCsv,
    ));
    final async = ref.watch(provider);
    final howToReady = useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.duel,
        icon: Icons.military_tech_rounded,
        accent: GameAccent.duel.accent,
        badgeBg: GameAccent.duel.badgeBg,
        stepAccent: GameAccent.duel.stepAccent,
        title: '1v1 Duel',
        startLabel: 'Start match',
        steps: const [
          'Lay the phone flat on the table between you.',
          'Same question, 2 options each — mirrored top and bottom.',
          'Both pick (or pass) first — correct answer reveals only '
              'when both have locked in.',
        ],
      ),
    );

    void exit() => context.canPop() ? context.pop() : context.go('/games');

    final duelState = async.asData?.value;
    final matchQuestions = duelState?.matchQuestions ?? const [];
    final matchOver = duelState?.phase == DuelPhase.matchOver;
    useGameScreenOpenedAnalytics(ref, RevisionGameNames.duel);
    useGameSessionAnalytics(
      ref: ref,
      gameName: RevisionGameNames.duel,
      readyToStart: howToReady && matchQuestions.isNotEmpty,
      sessionComplete: matchOver,
      correctCount: (duelState?.p1Score ?? 0) + (duelState?.p2Score ?? 0),
      totalRounds: matchQuestions.length,
      sessionKey: matchQuestions.isEmpty
          ? null
          : matchQuestions.map((e) => e.id).join(','),
    );

    // Auto-advance after a round resolves (winner or both wrong).
    useEffect(
      () {
        final state = async.asData?.value;
        if (state == null || !howToReady) return null;
        if (state.phase == DuelPhase.matchOver) return null;
        if (!state.revealedAnswer) return null;
        final timer = Timer(const Duration(milliseconds: 900), () {
          ref.read(provider.notifier).nextQuestion();
        });
        return timer.cancel;
      },
      [
        async.asData?.value.questionIndex,
        async.asData?.value.revealedAnswer,
        howToReady,
      ],
    );

    return Scaffold(
      backgroundColor: RgColors.pageBg,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: RgColors.teal),
          ),
          error: (e, _) => Center(
            child: Text('$e', style: RgText.body(color: RgColors.muted)),
          ),
          data: (state) {
            if (state.error != null && state.matchQuestions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: RgText.body(size: 13, color: RgColors.muted),
                  ),
                ),
              );
            }

            if (state.phase == DuelPhase.matchOver) {
              return _MatchOverView(
                p1Score: state.p1Score,
                p2Score: state.p2Score,
                onRematch: () => ref.read(provider.notifier).playAgain(),
                onExit: exit,
              );
            }

            final q = state.current;
            if (q == null) {
              return Center(
                child: Text(
                  'No question',
                  style: RgText.body(color: RgColors.muted),
                ),
              );
            }

            return Column(
              children: [
                // Player 2 — top half, rotated 180°.
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: _PlayerHalf(
                      subject: q.subject,
                      questionNumber: state.questionNumber,
                      question: q.questionForLang(p2Lang),
                      options: q.optionsForLang(p2Lang),
                      answerIndex: q.answerIndex,
                      locked: state.p2Locked,
                      selectedIndex: state.p2SelectedIndex,
                      passed: state.p2Passed,
                      wrongIndex: state.p2WrongIndex,
                      revealed: state.revealedAnswer,
                      gotItRight: state.playerGotItRight(DuelPlayer.two),
                      language: p2Lang,
                      onLangChanged: (v) => p2LangState.value = v,
                      onTap: (i) =>
                          ref.read(provider.notifier).tap(DuelPlayer.two, i),
                      onPass: () =>
                          ref.read(provider.notifier).pass(DuelPlayer.two),
                    ),
                  ),
                ),
                _ScoreSeam(
                  p1Score: state.p1Score,
                  p2Score: state.p2Score,
                  onExit: exit,
                ),
                // Player 1 — bottom half, upright.
                Expanded(
                  child: _PlayerHalf(
                    subject: q.subject,
                    questionNumber: state.questionNumber,
                    question: q.questionForLang(p1Lang),
                    options: q.optionsForLang(p1Lang),
                    answerIndex: q.answerIndex,
                    locked: state.p1Locked,
                    selectedIndex: state.p1SelectedIndex,
                    passed: state.p1Passed,
                    wrongIndex: state.p1WrongIndex,
                    revealed: state.revealedAnswer,
                    gotItRight: state.playerGotItRight(DuelPlayer.one),
                    language: p1Lang,
                    onLangChanged: (v) {
                      p1LangState.value = v;
                      persistAppLanguage(ref, v);
                    },
                    onTap: (i) =>
                        ref.read(provider.notifier).tap(DuelPlayer.one, i),
                    onPass: () =>
                        ref.read(provider.notifier).pass(DuelPlayer.one),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlayerHalf extends StatelessWidget {
  const _PlayerHalf({
    required this.subject,
    required this.questionNumber,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.locked,
    required this.selectedIndex,
    required this.passed,
    required this.wrongIndex,
    required this.revealed,
    required this.gotItRight,
    required this.language,
    required this.onLangChanged,
    required this.onTap,
    required this.onPass,
  });

  final String subject;
  final int questionNumber;
  final String question;
  final List<String> options;
  final int answerIndex;
  final bool locked;
  final int? selectedIndex;
  final bool passed;
  final int? wrongIndex;
  final bool revealed;

  /// This half scored the point (correct choice after reveal).
  final bool gotItRight;
  final String language;
  final ValueChanged<String> onLangChanged;
  final ValueChanged<int> onTap;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final waiting = locked && !revealed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: RgMonoLabel('Q$questionNumber · $subject')),
              RgLangToggle(
                language: language,
                onChanged: onLangChanged,
                minHeight: 28,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: context.readingFont(RgText.display(size: 15, height: 1.28)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _DuelOption(
              label: options[i],
              enabled: !locked && !revealed,
              isSelected: !revealed && selectedIndex == i,
              isCorrect: revealed && i == answerIndex,
              isWrong: revealed && wrongIndex == i,
              dimmed:
                  (waiting && selectedIndex != i) ||
                  (revealed && i != answerIndex && wrongIndex != i),
              onTap: () => onTap(i),
            ),
          ],
          if (!locked && !revealed) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPass,
                style: TextButton.styleFrom(
                  foregroundColor: RgColors.muted,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Pass',
                  style: RgText.mono(size: 11, color: RgColors.muted),
                ),
              ),
            ),
          ] else if (waiting && passed) ...[
            const SizedBox(height: 10),
            Text(
              'Passed — waiting…',
              textAlign: TextAlign.center,
              style: RgText.mono(size: 10, color: RgColors.muted),
            ),
          ] else if (revealed && passed) ...[
            const SizedBox(height: 10),
            Text(
              'Passed',
              textAlign: TextAlign.center,
              style: RgText.mono(size: 10, color: RgColors.muted),
            ),
          ] else if (revealed && gotItRight) ...[
            const SizedBox(height: 10),
            Text(
              'Point!',
              textAlign: TextAlign.center,
              style: RgText.mono(size: 10, color: RgColors.tealDeep),
            ),
          ],
        ],
      ),
    );
  }
}

class _DuelOption extends StatelessWidget {
  const _DuelOption({
    required this.label,
    required this.enabled,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var bg = RgColors.card;
    var borderColor = RgColors.border14;
    var textColor = RgColors.ink;

    if (isWrong) {
      bg = RgColors.wrongBg;
      borderColor = RgColors.wrong;
      textColor = RgColors.wrongText;
    } else if (isCorrect) {
      bg = RgColors.correctBg;
      borderColor = RgColors.teal;
      textColor = RgColors.tealDeep;
    } else if (isSelected) {
      bg = RgColors.neutralFill;
      borderColor = RgColors.ink;
      textColor = RgColors.ink;
    }

    Widget option = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RgRadius.md),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RgRadius.md),
        child: Stack(
          children: [
            if (isWrong)
              const Positioned.fill(
                child: CustomPaint(painter: _HazardStripePainter()),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (isCorrect) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: RgColors.tealDeep,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: RgText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isWrong || isSelected)
              Positioned(
                top: -6,
                right: -22,
                child: Transform.rotate(
                  angle: 0.489,
                  child: Container(
                    color: isWrong ? RgColors.wrong : RgColors.ink,
                    padding: const EdgeInsets.fromLTRB(26, 8, 26, 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 11,
                          color: RgColors.onDark,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'LOCKED',
                          style: RgText.mono(
                            size: 9,
                            letterSpacingEm: 0.06,
                            color: RgColors.onDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (dimmed) option = Opacity(opacity: 0.55, child: option);

    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(RgRadius.md),
        child: option,
      ),
    );
  }
}

/// Diagonal hazard stripes painted across a locked-out option.
class _HazardStripePainter extends CustomPainter {
  const _HazardStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RgColors.wrong.withValues(alpha: 0.16)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    const gap = 12.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HazardStripePainter oldDelegate) => false;
}

/// Solid teal seam carrying the running score, upright between the two halves.
class _ScoreSeam extends StatelessWidget {
  const _ScoreSeam({
    required this.p1Score,
    required this.p2Score,
    required this.onExit,
  });

  final int p1Score;
  final int p2Score;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: RgColors.teal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SeamScore(label: 'P2', score: p2Score, alignEnd: false),
          Material(
            color: RgColors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onExit,
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RgColors.tealDeep,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RgColors.onDark.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: RgColors.pageBg,
                ),
              ),
            ),
          ),
          _SeamScore(label: 'P1', score: p1Score, alignEnd: true),
        ],
      ),
    );
  }
}

class _SeamScore extends StatelessWidget {
  const _SeamScore({
    required this.label,
    required this.score,
    required this.alignEnd,
  });

  final String label;
  final int score;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: RgText.mono(
            size: 8,
            weight: FontWeight.w600,
            letterSpacingEm: 0.1,
            color: RgColors.onDark.withValues(alpha: 0.65),
          ),
        ),
        Text(
          '$score',
          style: RgText.mono(size: 26, height: 1, color: RgColors.onDark),
        ),
      ],
    );
  }
}

class _MatchOverView extends StatelessWidget {
  const _MatchOverView({
    required this.p1Score,
    required this.p2Score,
    required this.onRematch,
    required this.onExit,
  });

  final int p1Score;
  final int p2Score;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 2,
            child: _EndHalf(
              ownLabel: 'P2',
              otherLabel: 'P1',
              ownScore: p2Score,
              otherScore: p1Score,
              onExit: onExit,
            ),
          ),
        ),
        _EndSeam(onRematch: onRematch),
        Expanded(
          child: _EndHalf(
            ownLabel: 'P1',
            otherLabel: 'P2',
            ownScore: p1Score,
            otherScore: p2Score,
            onExit: onExit,
          ),
        ),
      ],
    );
  }
}

class _EndHalf extends StatelessWidget {
  const _EndHalf({
    required this.ownLabel,
    required this.otherLabel,
    required this.ownScore,
    required this.otherScore,
    required this.onExit,
  });

  final String ownLabel;
  final String otherLabel;
  final int ownScore;
  final int otherScore;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final won = ownScore > otherScore;
    final lost = ownScore < otherScore;

    final String stampText;
    final Color stampBg;
    final Color stampFg;
    final Color scoreColor;
    final String caption;
    final double stampAngle;
    if (won) {
      stampText = 'VICTORY';
      stampBg = RgColors.teal;
      stampFg = RgColors.onDark;
      scoreColor = RgColors.teal;
      caption = 'You win, $ownLabel';
      stampAngle = -0.052;
    } else if (lost) {
      stampText = 'DEFEAT';
      stampBg = RgColors.stampNeutralBg;
      stampFg = RgColors.muted;
      scoreColor = RgColors.mutedSoft;
      caption = '$otherLabel wins';
      stampAngle = 0.052;
    } else {
      stampText = 'DRAW';
      stampBg = RgColors.warningBg;
      stampFg = RgColors.warningText;
      scoreColor = RgColors.warning;
      caption = 'Evenly matched';
      stampAngle = -0.052;
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (won) ...[
          const Icon(Icons.star_rounded, size: 28, color: RgColors.warning),
          const SizedBox(height: 4),
        ],
        Transform.rotate(
          angle: stampAngle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: stampBg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              stampText,
              style: RgText.mono(
                size: 12,
                letterSpacingEm: 0.1,
                color: stampFg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$ownScore–$otherScore',
          style: RgText.display(
            size: 42,
            weight: FontWeight.w800,
            height: 1,
            color: scoreColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(caption, style: RgText.body(size: 13, weight: FontWeight.w600)),
        TextButton(
          onPressed: onExit,
          style: TextButton.styleFrom(foregroundColor: RgColors.muted),
          child: Text(
            'Exit',
            style: RgText.body(size: 12, color: RgColors.muted),
          ),
        ),
      ],
    );

    if (!won) return Center(child: content);

    // Winner half gets a scatter of confetti behind the stamp.
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(top: 14, left: 22, child: _Confetti(RgColors.warning)),
        const Positioned(
          top: 34,
          right: 26,
          child: _Confetti(RgColors.info, round: true),
        ),
        const Positioned(top: 10, right: 70, child: _Confetti(RgColors.teal)),
        const Positioned(
          bottom: 16,
          left: 40,
          child: _Confetti(RgColors.wrong, round: true),
        ),
        const Positioned(
          bottom: 26,
          right: 20,
          child: _Confetti(RgColors.warning),
        ),
        Center(child: content),
      ],
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti(this.color, {this.round = false});

  final Color color;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: round ? 0 : 0.35,
      child: Container(
        width: round ? 7 : 9,
        height: round ? 7 : 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(round ? 8 : 2),
        ),
      ),
    );
  }
}

class _EndSeam extends StatelessWidget {
  const _EndSeam({required this.onRematch});

  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      width: double.infinity,
      color: RgColors.teal,
      alignment: Alignment.center,
      child: Material(
        color: RgColors.transparent,
        child: InkWell(
          onTap: onRematch,
          borderRadius: BorderRadius.circular(RgRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: RgColors.pageBg,
              borderRadius: BorderRadius.circular(RgRadius.pill),
            ),
            child: Text(
              'Rematch',
              style: RgText.body(
                size: 13,
                weight: FontWeight.w700,
                color: RgColors.teal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
