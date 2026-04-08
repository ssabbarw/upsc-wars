import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class RevisionQueueScreen extends HookConsumerWidget {
  const RevisionQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(revisionQueueItemsProvider);
    final scheme = Theme.of(context).colorScheme;

    Future<void> start(List<dynamic> items) async {
      final create = await ref.read(createSessionUseCaseProvider.future);
      final count = items.length > 50 ? 50 : items.length;
      if (count == 0) return;
      final id = await create.execute(const SessionConfig(
        subjectSlug: 'revision',
        mode: 'learning',
        questionCount: 50,
        isTimed: true,
        timeLimitSecs: 60,
        language: 'en',
      ).copyWith(questionCount: count));
      if (context.mounted) context.go('/test/$id');
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [
                IconButton(onPressed: () => context.go('/'), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: async.when(
                    data: (items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Revision queue', style: AppTextStyles.h2().copyWith(color: scheme.onSurface)),
                      Text('${items.length} questions', style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant)),
                    ]),
                    loading: () => Text('Revision queue', style: AppTextStyles.h2()),
                    error: (e, st) => Text('Revision queue', style: AppTextStyles.h2()),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: async.when(
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => start(items),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            'Start revision session',
                            style: AppTextStyles.label(),
                          ),
                        ),
                      ),
                loading: () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'Start revision session',
                      style: AppTextStyles.label(),
                    ),
                  ),
                ),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: async.when(
                loading: () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 8,
                  separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (c, i) => Container(height: 84, decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                error: (e, st) => Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(revisionQueueItemsProvider),
                    child: Text('Retry', style: AppTextStyles.label()),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Your revision queue is empty', style: AppTextStyles.h3().copyWith(color: scheme.onSurface)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Questions you get wrong or bookmark will appear here', style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                    );
                  }
                  final wrong = items.where((e) => e.reason == 'wrong').toList();
                  final bookmarked = items.where((e) => e.reason == 'bookmarked').toList();
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (wrong.isNotEmpty) ...[
                        Text('WRONG ANSWERS (${wrong.length})', style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.sm),
                        ...wrong.map((e) => _Row(item: e)),
                      ],
                      if (bookmarked.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text('BOOKMARKED (${bookmarked.length})', style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.sm),
                        ...bookmarked.map((e) => _Row(item: e)),
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

class _Row extends HookConsumerWidget {
  const _Row({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subj = SubjectConstants.bySlug(item.subjectSlug)?.displayName ?? item.subjectSlug;
    final badWrong = item.reason == 'wrong';
    final badgeBg = badWrong ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg) : (isDark ? AppColors.primaryDeep : AppColors.primaryLight);
    final badgeFg = badWrong ? (isDark ? AppColors.wrongTextDark : AppColors.wrongText) : (isDark ? AppColors.onPrimary : AppColors.primaryDeep);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$subj · ${item.topicSlug}', style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs),
        Text(item.questionStem, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMd().copyWith(color: scheme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Text(badWrong ? 'Wrong' : 'Bookmarked', style: AppTextStyles.caption().copyWith(color: badgeFg)),
          ),
          const SizedBox(width: AppSpacing.md),
          _Dots(streak: item.correctStreak),
        ]),
      ]),
    );
  }
}

class _Dots extends HookConsumerWidget {
  const _Dots({required this.streak});
  final int streak;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    Widget dot(bool filled) => Container(width: 8, height: 8, decoration: BoxDecoration(color: filled ? AppColors.correct : AppColors.transparent, borderRadius: BorderRadius.circular(99), border: Border.all(color: filled ? AppColors.correct : border, width: 1)));
    return Row(children: [dot(streak >= 1), const SizedBox(width: 4), dot(streak >= 2)]);
  }
}

extension on SessionConfig {
  SessionConfig copyWith({int? questionCount}) => SessionConfig(
        subjectSlug: subjectSlug,
        topicSlug: topicSlug,
        subTopicSlug: subTopicSlug,
        mode: mode,
        questionCount: questionCount ?? this.questionCount,
        isTimed: isTimed,
        timeLimitSecs: timeLimitSecs,
        language: language,
      );
}
