import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'timeline_sorter_controller.dart';

class TimelineSorterScreen extends HookConsumerWidget {
  const TimelineSorterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timelineSorterControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _GameAppBar(title: 'Timeline Sorter'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (state) {
                  final set = state.current;
                  if (set == null) {
                    return Center(
                      child: Text(
                        state.error ?? 'No content',
                        style: AppTextStyles.body()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  final revealed = state.phase == TimelinePhase.revealed;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    children: [
                      Text(
                        set.theme,
                        style: AppTextStyles.h3()
                            .copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        set.subject,
                        style: AppTextStyles.caption()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        revealed
                            ? 'Correct order'
                            : 'Tap two items to swap. Then check.',
                        style: AppTextStyles.bodySm()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...List.generate(state.order.length, (slot) {
                        final item = set.items[state.order[slot]];
                        final selected = state.selectedSlot == slot;
                        Color bg;
                        Color borderColor = border;
                        if (revealed) {
                          bg = isDark
                              ? AppColors.correctBgDark
                              : AppColors.correctBg;
                          borderColor = AppColors.correct;
                        } else if (selected) {
                          bg = AppColors.primary.withValues(alpha: 0.15);
                          borderColor = AppColors.primary;
                        } else {
                          bg = isDark
                              ? AppColors.surfaceSecondaryDark
                              : AppColors.surfaceSecondaryLight;
                        }
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: revealed
                                  ? null
                                  : () => ref
                                      .read(
                                        timelineSorterControllerProvider
                                            .notifier,
                                      )
                                      .tapSlot(slot),
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
                                    width: selected || revealed ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${slot + 1}.',
                                      style: AppTextStyles.label().copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: AppTextStyles.body().copyWith(
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (revealed)
                                      Text(
                                        item.yearDisplay,
                                        style: AppTextStyles.label().copyWith(
                                          color: isDark
                                              ? AppColors.correctTextDark
                                              : AppColors.correctText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (revealed) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.isCorrect ? 'Nice — correct order.' : 'Not quite.',
                          style: AppTextStyles.label().copyWith(
                            color: state.isCorrect
                                ? AppColors.correct
                                : AppColors.wrong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          set.explanation,
                          style: AppTextStyles.body()
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: () => ref
                              .read(timelineSorterControllerProvider.notifier)
                              .nextSet(),
                          child: const Text('Next set'),
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: () => ref
                              .read(timelineSorterControllerProvider.notifier)
                              .check(),
                          child: const Text('Check'),
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
