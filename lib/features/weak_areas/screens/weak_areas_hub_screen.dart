import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_config.dart';
import '../../../core/domain/entities/weak_concept_group.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class WeakAreasHubScreen extends HookConsumerWidget {
  const WeakAreasHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subTopics = ref.watch(weakSubTopicGroupsProvider);
    final traps = ref.watch(weakTrapGroupsProvider);
    final loading = useState(false);

    Future<void> practiceAll() async {
      if (loading.value) return;
      loading.value = true;
      try {
        final create = await ref.read(createSessionUseCaseProvider.future);
        final items = await ref.read(revisionQueueItemsProvider.future);
        final count = items.length.clamp(1, 50);
        final id = await create.execute(SessionConfig(
          subject: 'revision',
          mode: 'learning',
          questionCount: count,
          isTimed: true,
          timeLimitSecs: 60,
          language: 'en',
        ));
        if (context.mounted) context.push('/test/$id');
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [
                IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Weak Areas', style: AppTextStyles.h2()),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading.value ? null : practiceAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: loading.value
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Practice All Weak Areas'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                children: [
                  // ── Sub-topics section ──────────────────────────────────
                  Text(
                    'Sub-topics',
                    style: AppTextStyles.label()
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  subTopics.when(
                    loading: () => _skeletonList(scheme),
                    error: (e, st) => _errorWidget(
                      () => ref.invalidate(weakSubTopicGroupsProvider)),
                    data: (groups) => groups.isEmpty
                        ? _emptySection('No sub-topic weak areas yet', scheme)
                        : Column(
                            children: groups
                                .map((g) => _SubTopicRow(
                                      group: g,
                                      border: border,
                                      scheme: scheme,
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── My Trap Patterns card ───────────────────────────────
                  traps.when(
                    loading: () => Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (groups) => _TrapPatternCard(
                      trapCount: groups.length,
                      border: border,
                      scheme: scheme,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonList(ColorScheme scheme) => Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      );

  Widget _errorWidget(VoidCallback retry) => Center(
        child: OutlinedButton(onPressed: retry, child: const Text('Retry')),
      );

  Widget _emptySection(String message, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          message,
          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
        ),
      );
}

class _TrapPatternCard extends StatelessWidget {
  const _TrapPatternCard({
    required this.trapCount,
    required this.border,
    required this.scheme,
  });

  final int trapCount;
  final Color border;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Trap Patterns',
                  style: AppTextStyles.bodyMd()
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  trapCount == 0
                      ? 'No trap patterns identified yet'
                      : 'Caught by $trapCount ${trapCount == 1 ? 'pattern' : 'patterns'}',
                  style: AppTextStyles.caption()
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (trapCount > 0)
            FilledButton(
              onPressed: () => context.push('/weak-areas/traps'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View My Traps'),
            ),
        ],
      ),
    );
  }
}

class _SubTopicRow extends StatelessWidget {
  const _SubTopicRow({
    required this.group,
    required this.border,
    required this.scheme,
  });
  final WeakSubTopicGroup group;
  final Color border;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          '/weak-areas/subtopic/${Uri.encodeComponent(group.subTopic)}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                group.subTopic,
                style: AppTextStyles.bodyMd().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                '${group.questionUuids.length} ${group.questionUuids.length == 1 ? 'question' : 'questions'} · got wrong ${group.failureCount} ${group.failureCount == 1 ? 'time' : 'times'}',
                style: AppTextStyles.caption()
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ]),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
        ]),
      ),
    );
  }
}
