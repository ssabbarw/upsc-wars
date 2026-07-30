import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/mini_game_feedback.dart';
import 'timeline_sorter_controller.dart';

class TimelineSorterScreen extends HookConsumerWidget {
  const TimelineSorterScreen({
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
    final provider = timelineSorterControllerProvider(
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
            const _GameAppBar(title: 'Timeline Sorter'),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (state) {
                  if (state.phase == TimelinePhase.sessionComplete) {
                    return _SessionCompleteView(
                      correct: state.correctCount,
                      total: state.session.length,
                      onPlayAgain: () =>
                          ref.read(provider.notifier).playAgain(),
                    );
                  }
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              set.theme,
                              style: AppTextStyles.h3()
                                  .copyWith(color: scheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${set.subject}  ·  ${state.setIndex + 1}/${state.session.length}',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              revealed
                                  ? 'Correct order'
                                  : 'Hold and drag to reorder, then check.',
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          buildDefaultDragHandles: false,
                          itemCount: state.order.length,
                          onReorderStart: revealed
                              ? null
                              : (_) => HapticFeedback.lightImpact(),
                          onReorder: revealed
                              ? (_, _) {}
                              : (oldIndex, newIndex) => ref
                                  .read(provider.notifier)
                                  .reorder(oldIndex, newIndex),
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final t = Curves.easeInOut
                                    .transform(animation.value);
                                return Material(
                                  elevation: 2 + 4 * t,
                                  color: Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  child: child,
                                );
                              },
                              child: child,
                            );
                          },
                          itemBuilder: (context, slot) {
                            final item = set.items[state.order[slot]];
                            final Color bg;
                            final Color borderColor;
                            if (revealed) {
                              bg = isDark
                                  ? AppColors.correctBgDark
                                  : AppColors.correctBg;
                              borderColor = AppColors.correct;
                            } else {
                              bg = isDark
                                  ? AppColors.surfaceSecondaryDark
                                  : AppColors.surfaceSecondaryLight;
                              borderColor = border;
                            }

                            final tile = Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: borderColor,
                                  width: revealed ? 1.5 : 0.5,
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
                                    )
                                  else
                                    Icon(
                                      Icons.drag_handle_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                ],
                              ),
                            );

                            return KeyedSubtree(
                              key: ValueKey(state.order[slot]),
                              child: revealed
                                  ? tile
                                  : ReorderableDelayedDragStartListener(
                                      index: slot,
                                      child: tile,
                                    ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: revealed
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  MiniGameResultBanner(
                                    correct: state.isCorrect,
                                    text: state.isCorrect
                                        ? 'Nice — correct order.'
                                        : 'Not quite.',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    set.explanation,
                                    style: AppTextStyles.body()
                                        .copyWith(color: scheme.onSurface),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  FilledButton(
                                    onPressed: () => ref
                                        .read(provider.notifier)
                                        .nextSet(),
                                    child: const Text('Next set'),
                                  ),
                                ],
                              )
                            : FilledButton(
                                onPressed: () =>
                                    ref.read(provider.notifier).check(),
                                child: const Text('Check'),
                              ),
                      ),
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
