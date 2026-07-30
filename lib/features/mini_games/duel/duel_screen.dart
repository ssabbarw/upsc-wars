import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'duel_controller.dart';

class DuelScreen extends HookConsumerWidget {
  const DuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(duelControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-advance after a round resolves (winner or both wrong).
    useEffect(() {
      final state = async.asData?.value;
      if (state == null) return null;
      if (state.phase == DuelPhase.matchOver) return null;
      if (!state.revealedAnswer) return null;
      final timer = Timer(const Duration(milliseconds: 900), () {
        ref.read(duelControllerProvider.notifier).nextQuestion();
      });
      return timer.cancel;
    }, [
      async.asData?.value.questionIndex,
      async.asData?.value.revealedAnswer,
    ]);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (state) {
          if (state.error != null && state.matchQuestions.isEmpty) {
            return SafeArea(
              child: Center(
                child: Text(
                  state.error!,
                  style: AppTextStyles.body()
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            );
          }

          if (state.phase == DuelPhase.matchOver) {
            return _MatchOverView(
              p1Score: state.p1Score,
              p2Score: state.p2Score,
              onPlayAgain: () =>
                  ref.read(duelControllerProvider.notifier).playAgain(),
              onExit: () =>
                  context.canPop() ? context.pop() : context.go('/games'),
            );
          }

          final q = state.current;
          if (q == null) {
            return const Center(child: Text('No question'));
          }

          return Column(
            children: [
              // Player 2 — top half, rotated 180°
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _PlayerHalf(
                    label: 'Player 2',
                    question: q.question,
                    options: q.options,
                    locked: state.p2Locked,
                    revealed: state.revealedAnswer,
                    answerIndex: q.answerIndex,
                    highlightWinner: state.roundWinner == DuelPlayer.two,
                    onTap: (i) => ref
                        .read(duelControllerProvider.notifier)
                        .tap(DuelPlayer.two, i),
                  ),
                ),
              ),
              // Center score strip (readable upright for whoever glances)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.lg,
                ),
                color: isDark
                    ? AppColors.surfaceSecondaryDark
                    : AppColors.surfaceSecondaryLight,
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/games'),
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'P2  ${state.p2Score}  —  ${state.p1Score}  P1   ·  Q${state.questionNumber}/$duelMatchLength',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Player 1 — bottom half, upright
              Expanded(
                child: _PlayerHalf(
                  label: 'Player 1',
                  question: q.question,
                  options: q.options,
                  locked: state.p1Locked,
                  revealed: state.revealedAnswer,
                  answerIndex: q.answerIndex,
                  highlightWinner: state.roundWinner == DuelPlayer.one,
                  onTap: (i) => ref
                      .read(duelControllerProvider.notifier)
                      .tap(DuelPlayer.one, i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerHalf extends StatelessWidget {
  const _PlayerHalf({
    required this.label,
    required this.question,
    required this.options,
    required this.locked,
    required this.revealed,
    required this.answerIndex,
    required this.highlightWinner,
    required this.onTap,
  });

  final String label;
  final String question;
  final List<String> options;
  final bool locked;
  final bool revealed;
  final int answerIndex;
  final bool highlightWinner;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: highlightWinner
                    ? AppColors.correct
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Center(
                child: Text(
                  question,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3().copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            if (revealed && highlightWinner)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Point!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label().copyWith(
                    color: AppColors.correct,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (revealed && !highlightWinner && locked)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Locked out',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption()
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: _OptionButton(
                      label: options[i],
                      enabled: !locked && !revealed,
                      border: border,
                      isDark: isDark,
                      showCorrect: revealed && i == answerIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.enabled,
    required this.border,
    required this.isDark,
    required this.showCorrect,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Color border;
  final bool isDark;
  final bool showCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    Color borderColor = border;
    if (showCorrect) {
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      borderColor = AppColors.correct;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: borderColor,
              width: showCorrect ? 1.5 : 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchOverView extends StatelessWidget {
  const _MatchOverView({
    required this.p1Score,
    required this.p2Score,
    required this.onPlayAgain,
    required this.onExit,
  });

  final int p1Score;
  final int p2Score;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 2,
            child: _EndHalf(
              title: 'Player 2',
              ownScore: p2Score,
              otherScore: p1Score,
              onPlayAgain: onPlayAgain,
              onExit: onExit,
            ),
          ),
        ),
        Expanded(
          child: _EndHalf(
            title: 'Player 1',
            ownScore: p1Score,
            otherScore: p2Score,
            onPlayAgain: onPlayAgain,
            onExit: onExit,
          ),
        ),
      ],
    );
  }
}

class _EndHalf extends StatelessWidget {
  const _EndHalf({
    required this.title,
    required this.ownScore,
    required this.otherScore,
    required this.onPlayAgain,
    required this.onExit,
  });

  final String title;
  final int ownScore;
  final int otherScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = ownScore > otherScore
        ? 'You win'
        : ownScore < otherScore
            ? 'You lose'
            : 'Draw';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTextStyles.caption()
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$ownScore – $otherScore',
              style: AppTextStyles.h1().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              result,
              style: AppTextStyles.h3().copyWith(
                color: ownScore >= otherScore
                    ? AppColors.correct
                    : AppColors.wrong,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onPlayAgain,
              child: const Text('Play again'),
            ),
            TextButton(
              onPressed: onExit,
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}
