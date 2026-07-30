import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'connect_the_dots_controller.dart';

class ConnectTheDotsScreen extends HookConsumerWidget {
  const ConnectTheDotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectTheDotsControllerProvider);
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
                        item.subject,
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
                                  : () => ref
                                      .read(
                                        connectTheDotsControllerProvider
                                            .notifier,
                                      )
                                      .select(i),
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
                        Text(
                          state.selectedIndex == item.answerIndex
                              ? 'Correct'
                              : 'Not quite',
                          style: AppTextStyles.label().copyWith(
                            color: state.selectedIndex == item.answerIndex
                                ? AppColors.correct
                                : AppColors.wrong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.explanation,
                          style: AppTextStyles.body()
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: () => ref
                              .read(connectTheDotsControllerProvider.notifier)
                              .next(),
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
