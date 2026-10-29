import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../domain/topic_list_sort_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../practice_tests/domain/practice_scope.dart';
import '../../practice_tests/providers/practice_catalog_provider.dart';
import '../providers/subject_detail_providers.dart';
import '../../../l10n/l10n.dart';

class TopicsListScreen extends HookConsumerWidget {
  const TopicsListScreen({super.key, required this.subject});

  /// Subject selected when the screen opens. Pills can switch away from it.
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubject = useState(subject);
    final sortMode = useState(TopicListSortMode.alphabetical);
    final query = useState('');
    final searchController = useTextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subjectSlug = selectedSubject.value;

    final topicsAsync = ref.watch(subjectTopicsProvider(subjectSlug));
    final progressByTopic =
        ref
            .watch(practiceCatalogProvider)
            .asData
            ?.value
            .topicProgress[subjectSlug] ??
        const <String, PracticeScopeProgress>{};

    final hPadding = AppBreakpoints.fullScreenHPadding(
      MediaQuery.sizeOf(context).width,
    );

    void selectSubject(String slug) {
      if (slug == subjectSlug) return;
      searchController.clear();
      query.value = '';
      selectedSubject.value = slug;
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: hPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      color: scheme.onSurface,
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.practiceBrowseTopics,
                            style: AppTextStyles.h2().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          topicsAsync.when(
                            data: (topics) => Text(
                              '${topics.length} topics',
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _SubjectPills(
                selected: subjectSlug,
                borderColor: borderColor,
                onSelected: selectSubject,
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => query.value = value,
                  style: AppTextStyles.body().copyWith(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: context.l10n.topicSearchHint,
                    hintStyle: AppTextStyles.body().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: scheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TopicSortMenu(
                    sortMode: sortMode.value,
                    onSortChanged: (mode) => sortMode.value = mode,
                  ),
                ),
              ),
              Expanded(
                child: topicsAsync.when(
                  loading: () => _LoadingSkeleton(),
                  error: (e, _) => _ErrorState(
                    onRetry: () =>
                        ref.invalidate(subjectTopicsProvider(subjectSlug)),
                  ),
                  data: (topics) {
                    if (topics.isEmpty) {
                      return _EmptyState();
                    }
                    final needle = query.value.trim().toLowerCase();
                    final matched = needle.isEmpty
                        ? topics
                        : topics
                              .where(
                                (topic) =>
                                    topic.displayName.toLowerCase().contains(
                                      needle,
                                    ) ||
                                    topic.topic.toLowerCase().contains(needle),
                              )
                              .toList();
                    if (matched.isEmpty) {
                      return Center(
                        child: Text(
                          context.l10n.topicNoMatch,
                          style: AppTextStyles.body().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final sorted = _sortTopics(
                      matched,
                      sortMode.value,
                      progressByTopic: progressByTopic,
                    );
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= AppBreakpoints.tablet;
                        if (isWide) {
                          return GridView.builder(
                            primary: false,
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.xxl,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  childAspectRatio: 2.05,
                                ),
                            itemCount: sorted.length,
                            itemBuilder: (context, i) => _TopicCard(
                              topic: sorted[i],
                              subject: subjectSlug,
                              borderColor: borderColor,
                              progress:
                                  progressByTopic[sorted[i].topic] ??
                                  PracticeScopeProgress.empty,
                            ),
                          );
                        }
                        return ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          itemCount: sorted.length + 1,
                          separatorBuilder: (context, index) {
                            if (index == sorted.length - 1) {
                              return const SizedBox(height: AppSpacing.xl);
                            }
                            return const SizedBox(
                              height: AppSpacing.cardListGap,
                            );
                          },
                          itemBuilder: (context, i) {
                            if (i == sorted.length) {
                              return const Center(child: ContactUsTextButton());
                            }
                            return _TopicCard(
                              topic: sorted[i],
                              subject: subjectSlug,
                              borderColor: borderColor,
                              progress:
                                  progressByTopic[sorted[i].topic] ??
                                  PracticeScopeProgress.empty,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectPills extends StatelessWidget {
  const _SubjectPills({
    required this.selected,
    required this.borderColor,
    required this.onSelected,
  });

  final String selected;
  final Color borderColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: SubjectConstants.ordered.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final def = SubjectConstants.ordered[i];
          final isSelected = def.slug == selected;
          return GestureDetector(
            onTap: () => onSelected(def.slug),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? AppColors.primary : borderColor,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                def.displayName,
                style: AppTextStyles.labelSm().copyWith(
                  color: isSelected
                      ? AppColors.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Sort: chips + ordering ─────────────────────────────────────────────────────

List<TopicInfo> _sortTopics(
  List<TopicInfo> topics,
  TopicListSortMode mode, {
  required Map<String, PracticeScopeProgress> progressByTopic,
}) {
  final copy = List<TopicInfo>.from(topics);
  switch (mode) {
    case TopicListSortMode.alphabetical:
      copy.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    case TopicListSortMode.accuracy:
      copy.sort((a, b) {
        final aAcc = progressByTopic[a.topic]?.accuracyPercent;
        final bAcc = progressByTopic[b.topic]?.accuracyPercent;
        if ((aAcc == null) != (bAcc == null)) return aAcc == null ? 1 : -1;
        if (aAcc == null && bAcc == null) {
          return a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
        }
        final byAcc = aAcc!.compareTo(bAcc!);
        if (byAcc != 0) return byAcc;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
    case TopicListSortMode.coverage:
      copy.sort((a, b) {
        final aPct = progressByTopic[a.topic]?.completionPercent ?? 0;
        final bPct = progressByTopic[b.topic]?.completionPercent ?? 0;
        final byPct = aPct.compareTo(bPct);
        if (byPct != 0) return byPct;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
  }
  return copy;
}

class _TopicSortMenu extends StatelessWidget {
  const _TopicSortMenu({required this.sortMode, required this.onSortChanged});

  final TopicListSortMode sortMode;
  final ValueChanged<TopicListSortMode> onSortChanged;

  String _label(BuildContext context, TopicListSortMode mode) {
    switch (mode) {
      case TopicListSortMode.accuracy:
        return context.l10n.statsAccuracyLabel;
      case TopicListSortMode.coverage:
        return context.l10n.statsSortLeastCovered;
      case TopicListSortMode.alphabetical:
        return context.l10n.statsSortAz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<TopicListSortMode>(
      initialValue: sortMode,
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        for (final mode in TopicListSortMode.values)
          PopupMenuItem(
            value: mode,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: mode == sortMode
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                Text(
                  _label(context, mode),
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _label(context, sortMode),
              style: AppTextStyles.labelSm().copyWith(color: scheme.onSurface),
            ),
            Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Topic Card ──────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.subject,
    required this.borderColor,
    required this.progress,
  });

  final TopicInfo topic;
  final String subject;
  final Color borderColor;
  final PracticeScopeProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String pct(double? value) => value == null ? '—' : '${value.round()}%';
    final testsValue = progress.testsTotal <= 0
        ? '0'
        : '${progress.testsDone}/${progress.testsTotal}';
    final fraction = progress.testsTotal <= 0
        ? 0.0
        : (progress.testsDone / progress.testsTotal).clamp(0.0, 1.0);
    final started = progress.testsDone > 0;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '/subject/${Uri.encodeComponent(subject)}/topic/${Uri.encodeComponent(topic.topic)}/tests',
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? AppColors.gray800
                        : AppColors.gray50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _TopicStat(
                      value: pct(progress.completionPercent),
                      label: context.l10n.topicStatComplete,
                      valueColor: started
                          ? AppColors.primary
                          : scheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    _TopicStat(
                      value: testsValue,
                      label: context.l10n.topicStatTestsDone,
                      valueColor: scheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    _TopicStat(
                      value: pct(progress.accuracyPercent),
                      label: context.l10n.topicStatAccuracy,
                      valueColor: _accuracyColor(progress.accuracyPercent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _accuracyColor(double? accuracy) {
  if (accuracy == null) return AppColors.gray400;
  if (accuracy < 60) return AppColors.wrong;
  if (accuracy < 80) return AppColors.warning;
  return AppColors.correct;
}

class _TopicStat extends StatelessWidget {
  const _TopicStat({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          style: AppTextStyles.label().copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Loading / Error / Empty states ─────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: 9,
      separatorBuilder: (context, index) {
        if (index == 7) return const SizedBox(height: AppSpacing.xl);
        return const SizedBox(height: AppSpacing.cardListGap);
      },
      itemBuilder: (context, index) {
        if (index == 8) {
          return const Center(child: ContactUsTextButton());
        }
        return Container(
          height: 88,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.topicLoadFailed,
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(
                context.l10n.commonRetry,
                style: AppTextStyles.label(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const ContactUsTextButton(),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.topic_outlined,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.topicsNoneFound,
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.topicsBankInstalling,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const ContactUsTextButton(),
          ],
        ),
      ),
    );
  }
}
