import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/mini_game_feedback.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _GameAppBar(title: 'Fact or Bluff'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (state) {
                  if (state.sessionComplete) {
                    return _SessionCompleteView(
                      correct: state.correctCount,
                      total: state.session.length,
                      onPlayAgain: () =>
                          ref.read(provider.notifier).playAgain(),
                    );
                  }
                  final item = state.current;
                  if (item == null) {
                    return Center(
                      child: Text(
                        state.error ?? 'No content',
                        style: AppTextStyles.body()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  final progress =
                      (state.secondsLeft / factOrBluffSeconds).clamp(0.0, 1.0);
                  final awaiting = state.isAwaitingAnswer;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${item.subject}  ·  ${state.index + 1}/${state.session.length}',
                              style: AppTextStyles.caption()
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const Spacer(),
                            Text(
                              'Streak ${state.streak}',
                              style: AppTextStyles.label().copyWith(
                                color: AppColors.streak,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? AppColors.surfaceTertiaryDark
                                : AppColors.surfaceTertiaryLight,
                            color: progress < 0.3
                                ? AppColors.wrong
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          awaiting
                              ? '${state.secondsLeft.ceil()}s'
                              : state.verdict == FactOrBluffVerdict.timeout
                                  ? 'Time’s up'
                                  : 'Answered',
                          style: AppTextStyles.caption()
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Expanded(
                          child: Center(
                            child: Text(
                              item.statement,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h2().copyWith(
                                color: scheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        if (!awaiting) ...[
                          MiniGameResultBanner(
                            correct:
                                state.verdict == FactOrBluffVerdict.correct,
                            center: true,
                            text: switch (state.verdict) {
                              FactOrBluffVerdict.correct => 'Correct',
                              FactOrBluffVerdict.wrong => 'Wrong',
                              FactOrBluffVerdict.timeout => 'Too slow',
                              FactOrBluffVerdict.none => '',
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            item.explanation,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body()
                                .copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton(
                            onPressed: () =>
                                ref.read(provider.notifier).next(),
                            child: const Text('Next'),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      ref.read(provider.notifier).answer(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.correct,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                  ),
                                  child: const Text('FACT'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => ref
                                      .read(provider.notifier)
                                      .answer(false),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.wrong,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                  ),
                                  child: const Text('BLUFF'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCompleteView extends StatelessWidget {
  const _SessionCompleteView({
    required this.correct,
    required this.total,
    required this.onPlayAgain,
  });

  final int correct;
  final int total;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Session complete',
              style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$correct / $total correct',
              style: AppTextStyles.h1().copyWith(
                color: correct * 2 >= total
                    ? AppColors.correct
                    : AppColors.wrong,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onPlayAgain,
              child: const Text('Play again'),
            ),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/games'),
              child: const Text('Back to games'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameAppBar extends StatelessWidget {
  const _GameAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/games'),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(child: Text(title, style: AppTextStyles.h2())),
        ],
      ),
    );
  }
}
