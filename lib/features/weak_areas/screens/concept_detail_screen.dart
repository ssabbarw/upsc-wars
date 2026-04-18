import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SubTopicDetailScreen extends HookConsumerWidget {
  const SubTopicDetailScreen({super.key, required this.subTopic});
  final String subTopic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subTopicsAsync = ref.watch(weakSubTopicGroupsProvider);
    final revisionAsync = ref.watch(revisionQueueItemsProvider);
    final loading = useState(false);

    final decoded = Uri.decodeComponent(subTopic);

    return subTopicsAsync.when(
      loading: () => _scaffold(context, decoded,
          child: const Center(child: CircularProgressIndicator())),
      error: (e, st) => _scaffold(context, decoded,
          child: Center(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(weakSubTopicGroupsProvider),
              child: const Text('Retry'),
            ),
          )),
      data: (groups) {
        final group =
            groups.where((g) => g.subTopic == decoded).firstOrNull;
        if (group == null) {
          return _scaffold(context, decoded,
              child: Center(
                child: Text('No data found',
                    style: AppTextStyles.bodySm()
                        .copyWith(color: scheme.onSurfaceVariant)),
              ));
        }

        Future<void> practice() async {
          if (loading.value) return;
          loading.value = true;
          try {
            final create = await ref.read(createSessionUseCaseProvider.future);
            final id = await create.execute(SessionConfig(
              subject: 'revision',
              mode: 'learning',
              questionCount: group.questionUuids.length,
              isTimed: true,
              timeLimitSecs: 60,
              language: 'en',
              specificQuestionUuids: group.questionUuids,
              analyticsFeatureKey: 'insights_dashboard',
            ));
            if (context.mounted) context.push('/test/$id');
          } finally {
            loading.value = false;
          }
        }

        return _scaffold(
          context,
          decoded,
          bottomBar: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading.value ? null : practice,
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
                    : const Text('Practice This Sub-topic'),
              ),
            ),
          ),
          child: revisionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (allItems) {
              final items = allItems
                  .where((i) => group.questionUuids.contains(i.questionUuid))
                  .toList();
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '${group.questionUuids.length} ${group.questionUuids.length == 1 ? 'question' : 'questions'} · got wrong ${group.failureCount} ${group.failureCount == 1 ? 'time' : 'times'}',
                      style: AppTextStyles.bodySm()
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Text(
                          item.questionStem,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd()
                              .copyWith(color: scheme.onSurface),
                        ),
                      )),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _scaffold(
    BuildContext context,
    String title, {
    required Widget child,
    Widget? bottomBar,
  }) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Row(children: [
              IconButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/weak-areas'),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h2(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          Expanded(child: child),
        ]),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
