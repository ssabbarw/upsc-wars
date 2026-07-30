import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/mini_game_feedback.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _GameAppBar(title: 'Connect the Dots'),
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
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    children: [
                      Text(
                        '${item.subject}  ·  ${state.index + 1}/${state.session.length}',
                        style: AppTextStyles.caption()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'What’s the hidden link?',
                        style: AppTextStyles.h3()
                            .copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: item.dots.map((dot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              dot,
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ...List.generate(item.options.length, (i) {
                        final selected = state.selectedIndex == i;
                        final isAnswer = i == item.answerIndex;
                        Color bg = isDark
                            ? AppColors.surfaceSecondaryDark
                            : AppColors.surfaceSecondaryLight;
                        Color borderColor = border;
                        if (state.revealed) {
                          if (isAnswer) {
                            bg = isDark
                                ? AppColors.correctBgDark
                                : AppColors.correctBg;
                            borderColor = AppColors.correct;
                          } else if (selected) {
                            bg = isDark
                                ? AppColors.wrongBgDark
                                : AppColors.wrongBg;
                            borderColor = AppColors.wrong;
                          }
                        }
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: state.revealed
                                  ? null
                                  : () =>
                                      ref.read(provider.notifier).select(i),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              child: Ink(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: borderColor,
                                    width: state.revealed &&
                                            (isAnswer || selected)
                                        ? 1.5
                                        : 0.5,
                                  ),
                                ),
                                child: Text(
                                  item.options[i],
                                  style: AppTextStyles.option()
                                      .copyWith(color: scheme.onSurface),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (state.revealed) ...[
                        const SizedBox(height: AppSpacing.lg),
                        MiniGameResultBanner(
                          correct: state.selectedIndex == item.answerIndex,
                          text: state.selectedIndex == item.answerIndex
                              ? 'Correct'
                              : 'Not quite',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.explanation,
                          style: AppTextStyles.body()
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: () => ref.read(provider.notifier).next(),
                          child: const Text('Next'),
                        ),
                      ],
                    ],
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
