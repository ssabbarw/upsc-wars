import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/session_subject_label.dart';
import '../../../core/presentation/topic_label.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../../../shared/widgets/top_snack_bar.dart';
import '../../../l10n/l10n.dart';

class BookmarksScreen extends HookConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookmarksListProvider);
    final scheme = Theme.of(context).colorScheme;

    Future<void> remove(dynamic item) async {
      final uc = await ref.read(removeBookmarkUseCaseProvider.future);
      await uc.execute(item.questionUuid);
      ref.invalidate(bookmarksListProvider);
      if (!context.mounted) return;
      showTopSnackBar(
        context,
        content: Text(context.l10n.bookmarkRemoved),
        action: SnackBarAction(
          label: context.l10n.commonUndo,
          onPressed: () async {
            final add = await ref.read(addBookmarkUseCaseProvider.future);
            await add.execute(item.questionUuid, note: item.userNote);
            ref.invalidate(bookmarksListProvider);
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                        context.canPop() ? context.pop() : context.go('/'),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: async.when(
                      data: (items) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bookmarks',
                            style: AppTextStyles.h2().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            context.l10n.bookmarksSavedCount(items.length),
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      loading: () =>
                          Text('Bookmarks', style: AppTextStyles.h2()),
                      error: (e, st) =>
                          Text('Bookmarks', style: AppTextStyles.h2()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 8,
                  separatorBuilder: (c, i) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (c, i) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                error: (e, st) => Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(bookmarksListProvider),
                    child: Text(
                      context.l10n.commonRetry,
                      style: AppTextStyles.label(),
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.bookmarksEmptyTitle,
                            style: AppTextStyles.h3().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l10n.bookmarksEmptyBody,
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: items.length,
                    separatorBuilder: (c, i) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (c, i) {
                      final b = items[i];
                      final subj = displayNameForSessionSubject(b.subject);
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final border = isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight;
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$subj · ${localizedTopicName(b.topic, language: Localizations.localeOf(context).languageCode)}',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              b.questionStem,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: context.readingFont(
                                AppTextStyles.bodyMd().copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            if (b.userNote != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                b.userNote!,
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(b.createdAt),
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => remove(b),
                                  child: Text(
                                    context.l10n.commonRemove,
                                    style: AppTextStyles.labelSm().copyWith(
                                      color: AppColors.wrong,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
