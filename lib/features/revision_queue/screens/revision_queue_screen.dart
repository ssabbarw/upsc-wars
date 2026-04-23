import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/screen_flow_analytics.dart';
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
    // null = "All subjects"
    final selectedSubject = useState<String?>(null);

    Future<void> start(List<dynamic> items) async {
      final create = await ref.read(createSessionUseCaseProvider.future);
      final count = items.length > 50 ? 50 : items.length;
      if (count == 0) return;
      final id = await create.execute(const SessionConfig(
        subject: 'revision',
        mode: 'learning',
        questionCount: 50,
        isTimed: true,
        timeLimitSecs: 60,
        language: 'en',
      ).copyWith(questionCount: count));
      if (context.mounted) context.push('/test/$id');
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [
                IconButton(
                  onPressed: () {
                    ScreenFlow.logAction(
                      ref,
                      screenName: ScreenFlow.revisionQueue,
                      actionId: 'back',
                      actionKind: 'back',
                    );
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: async.when(
                    data: (items) {
                      final filtered = _filter(items, selectedSubject.value);
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Revision queue', style: AppTextStyles.h2().copyWith(color: scheme.onSurface)),
                        Text(
                          '${filtered.length} question${filtered.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ]);
                    },
                    loading: () => Text('Revision queue', style: AppTextStyles.h2()),
                    error: (e, st) => Text('Revision queue', style: AppTextStyles.h2()),
                  ),
                ),
              ]),
            ),
            // ── Subject filter chips ────────────────────────────────────────
            async.whenOrNull(
              data: (items) {
                // Collect unique subjects that actually have queue items.
                final subjects = items
                    .map((e) => e.subject)
                    .toSet()
                    .toList()
                  ..sort();
                if (subjects.length <= 1) return const SizedBox.shrink();
                return _SubjectFilterChips(
                  subjects: subjects,
                  selected: selectedSubject.value,
                  onSelected: (s) => selectedSubject.value = s,
                );
              },
            ) ?? const SizedBox.shrink(),
            // ── Start button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: async.when(
                data: (items) {
                  final filtered = _filter(items, selectedSubject.value);
                  return filtered.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => start(filtered),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: Text(
                              'Start revision session',
                              style: AppTextStyles.label(),
                            ),
                          ),
                        );
                },
                loading: () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text('Start revision session', style: AppTextStyles.label()),
                  ),
                ),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 8,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, _) => Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                error: (e, st) => Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(revisionQueueItemsProvider),
                    child: Text('Retry', style: AppTextStyles.label()),
                  ),
                ),
                data: (items) {
                  final filtered = _filter(items, selectedSubject.value);
                  if (items.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Your revision queue is empty',
                            style: AppTextStyles.h3().copyWith(color: scheme.onSurface)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Questions you get wrong or bookmark will appear here',
                          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ]),
                    );
                  }
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No items for this subject.',
                        style: AppTextStyles.bodySm()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: filtered.map((e) => _Row(item: e)).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _filter(List<dynamic> items, String? subject) =>
      subject == null ? items : items.where((e) => e.subject == subject).toList();
}

// ────────────────────────────────────────────────────────────────────────────
// Subject filter chip row
// ────────────────────────────────────────────────────────────────────────────

class _SubjectFilterChips extends StatelessWidget {
  const _SubjectFilterChips({
    required this.subjects,
    required this.selected,
    required this.onSelected,
  });

  final List<String> subjects;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String? subject) {
      final isAll = subject == null;
      final label = isAll
          ? 'All'
          : (SubjectConstants.bySlug(subject)?.displayName ?? subject);
      final isSelected = selected == subject;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onSelected(isSelected ? null : subject),
          labelStyle: AppTextStyles.bodySm().copyWith(
            color: isSelected ? AppColors.onPrimary : scheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          selectedColor: AppColors.primary,
          backgroundColor: scheme.surfaceContainerLow,
          showCheckmark: false,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          chip(null), // "All" chip
          ...subjects.map(chip),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _Row extends HookConsumerWidget {
  const _Row({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subj = SubjectConstants.bySlug(item.subject)?.displayName ?? item.subject;
    final mastered = item.numberOfTimesAnsweredCorrectlyInRevision >= 2;
    final badgeBg = mastered
        ? (isDark ? AppColors.correctBgDark : AppColors.correctBg)
        : (isDark ? AppColors.primaryDeep : AppColors.primaryLight);
    final badgeFg = mastered
        ? (isDark ? AppColors.correctTextDark : AppColors.correctText)
        : (isDark ? AppColors.onPrimary : AppColors.primaryDeep);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$subj · ${item.topic}', style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs),
        Text(item.questionStem, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMd().copyWith(color: scheme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Text(mastered ? 'Mastered' : 'In queue', style: AppTextStyles.caption().copyWith(color: badgeFg)),
          ),
          const SizedBox(width: AppSpacing.md),
          _Dots(streak: item.numberOfTimesAnsweredCorrectlyInRevision),
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

