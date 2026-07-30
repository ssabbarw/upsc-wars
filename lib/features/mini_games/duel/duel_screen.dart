import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/mini_game_feedback.dart';
import 'duel_controller.dart';

class DuelScreen extends HookConsumerWidget {
  const DuelScreen({
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
    final provider = duelControllerProvider(
      (subjects: subjectsCsv, difficulties: difficultiesCsv),
    );
    final async = ref.watch(provider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-advance after a round resolves (winner or both wrong).
    useEffect(() {
      final state = async.asData?.value;
      if (state == null) return null;
      if (state.phase == DuelPhase.matchOver) return null;
      if (!state.revealedAnswer) return null;
      final timer = Timer(const Duration(milliseconds: 900), () {
        ref.read(provider.notifier).nextQuestion();
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
                  ref.read(provider.notifier).playAgain(),
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
                    onTap: (i) =>
                        ref.read(provider.notifier).tap(DuelPlayer.two, i),
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
                  onTap: (i) =>
                      ref.read(provider.notifier).tap(DuelPlayer.one, i),
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
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: MiniGameResultBanner(
                  correct: true,
                  text: 'Point!',
                  center: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      child: Column(
        children: [
          // Player 2 half — content hugged to the center fold, rotated 180°.
          Expanded(
            child: RotatedBox(
              quarterTurns: 2,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _EndCard(
                  playerLabel: 'Player 2',
                  ownScore: p2Score,
                  otherScore: p1Score,
                  onPlayAgain: onPlayAgain,
                  onExit: onExit,
                ),
              ),
            ),
          ),
          // Shared center ribbon — upright score both can glance at.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceSecondaryDark
                  : AppColors.surfaceSecondaryLight,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Text(
              'FINAL  ·  P2  $p2Score  —  $p1Score  P1',
              textAlign: TextAlign.center,
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          // Player 1 half — content hugged to the center fold, upright.
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: _EndCard(
                playerLabel: 'Player 1',
                ownScore: p1Score,
                otherScore: p2Score,
                onPlayAgain: onPlayAgain,
                onExit: onExit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.playerLabel,
    required this.ownScore,
    required this.otherScore,
    required this.onPlayAgain,
    required this.onExit,
  });

  final String playerLabel;
  final int ownScore;
  final int otherScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final won = ownScore > otherScore;
    final lost = ownScore < otherScore;
    final draw = !won && !lost;

    final Color accent;
    final Color bg;
    final String headline;
    final IconData icon;
    if (won) {
      accent = AppColors.correct;
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      headline = 'You win';
      icon = Icons.emoji_events_rounded;
    } else if (lost) {
      accent = AppColors.wrong;
      bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
      headline = 'You lose';
      icon = Icons.sentiment_dissatisfied_rounded;
    } else {
      accent = AppColors.warning;
      bg = isDark ? AppColors.warningBgDark : AppColors.warningBg;
      headline = 'Draw';
      icon = Icons.handshake_rounded;
    }

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerLabel.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Icon(icon, size: 40, color: accent),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  headline,
                  style: AppTextStyles.h1().copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$ownScore  –  $otherScore',
                  style: AppTextStyles.h2().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (draw)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Evenly matched',
                      style: AppTextStyles.caption()
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onPlayAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: const Text('Rematch'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: onExit,
                  style: TextButton.styleFrom(foregroundColor: accent),
                  child: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
