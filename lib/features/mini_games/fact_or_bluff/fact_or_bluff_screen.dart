import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'fact_or_bluff_controller.dart';

class FactOrBluffScreen extends HookConsumerWidget {
  const FactOrBluffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(factOrBluffControllerProvider);
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
                              item.subject,
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
                          Text(
                            switch (state.verdict) {
                              FactOrBluffVerdict.correct => 'Correct',
                              FactOrBluffVerdict.wrong => 'Wrong',
                              FactOrBluffVerdict.timeout => 'Too slow',
                              FactOrBluffVerdict.none => '',
                            },
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label().copyWith(
                              color: state.verdict == FactOrBluffVerdict.correct
                                  ? AppColors.correct
                                  : AppColors.wrong,
                              fontWeight: FontWeight.w700,
                            ),
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
                            onPressed: () => ref
                                .read(factOrBluffControllerProvider.notifier)
                                .next(),
                            child: const Text('Next'),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => ref
                                      .read(
                                        factOrBluffControllerProvider.notifier,
                                      )
                                      .answer(true),
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
                                      .read(
                                        factOrBluffControllerProvider.notifier,
                                      )
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
