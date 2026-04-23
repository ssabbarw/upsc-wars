import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../domain/topic_list_sort_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/accuracy_percentage_text.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../providers/subject_detail_providers.dart';
import '../widgets/topic_entry_bottom_sheet.dart';

class TopicsListScreen extends HookConsumerWidget {
  const TopicsListScreen({super.key, required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMode = useState(TopicListSortMode.dangerZone);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final subjectDef = SubjectConstants.bySlug(subject);
    final displayName = subjectDef?.displayName ?? subject;

    final topicsAsync = ref.watch(subjectTopicsProvider(subject));

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                          '$displayName Topics',
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
            topicsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (topics) {
                if (topics.isEmpty) return const SizedBox.shrink();
                return _TopicSortChips(
                  sortMode: sortMode.value,
                  onSortChanged: (m) => sortMode.value = m,
                );
              },
            ),
            // Topics list
            Expanded(
              child: topicsAsync.when(
                loading: () => _LoadingSkeleton(),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(subjectTopicsProvider(subject)),
                ),
                data: (topics) {
                  if (topics.isEmpty) {
                    return _EmptyState();
                  }
                  final sorted = _sortTopics(
                    List<TopicInfo>.from(topics),
                    sortMode.value,
                  );
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
                      return const SizedBox(height: AppSpacing.cardListGap);
                    },
                    itemBuilder: (context, i) {
                      if (i == sorted.length) {
                        return const Center(child: ContactUsTextButton());
                      }
                      return _TopicCard(
                        topic: sorted[i],
                        subject: subject,
                        displayName: displayName,
                        borderColor: borderColor,
                        isDark: isDark,
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

// ── Sort: chips + ordering ─────────────────────────────────────────────────────

List<TopicInfo> _sortTopics(List<TopicInfo> copy, TopicListSortMode mode) {
  switch (mode) {
    case TopicListSortMode.alphabetical:
      copy.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
      );
    case TopicListSortMode.accuracy:
      copy.sort((a, b) {
        final aAtt = a.attemptCount > 0;
        final bAtt = b.attemptCount > 0;
        if (aAtt != bAtt) return aAtt ? -1 : 1;
        if (!aAtt && !bAtt) {
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
        }
        final byAcc = (a.accuracyPercent ?? 0).compareTo(
          b.accuracyPercent ?? 0,
        );
        if (byAcc != 0) return byAcc;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });
    case TopicListSortMode.dangerZone:
      copy.sort((a, b) {
        final da = a.dangerSureWrongLast30 + a.dangerEducatedGuessWrongLast30;
        final db = b.dangerSureWrongLast30 + b.dangerEducatedGuessWrongLast30;
        if (db != da) return db.compareTo(da);
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });
  }
  return copy;
}

class _TopicSortChips extends StatelessWidget {
  const _TopicSortChips({
    required this.sortMode,
    required this.onSortChanged,
  });

  final TopicListSortMode sortMode;
  final ValueChanged<TopicListSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String label, TopicListSortMode mode) {
      final selected = sortMode == mode;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSortChanged(mode),
        labelStyle: AppTextStyles.bodySm().copyWith(
          color: selected ? AppColors.onPrimary : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            chip('Accuracy', TopicListSortMode.accuracy),
            const SizedBox(width: AppSpacing.sm),
            chip('Danger zone', TopicListSortMode.dangerZone),
            const SizedBox(width: AppSpacing.sm),
            chip('A – Z', TopicListSortMode.alphabetical),
          ],
        ),
      ),
    );
  }
}

// ── Topic Card ──────────────────────────────────────────────────────────────────

class _TopicLabeledLine extends StatelessWidget {
  const _TopicLabeledLine({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.subject,
    required this.displayName,
    required this.borderColor,
    required this.isDark,
  });

  final TopicInfo topic;
  final String subject;
  final String displayName;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWeak = topic.attemptCount > 0 && (topic.accuracyPercent ?? 100) < 50;
    final notStarted = topic.attemptCount == 0;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => showTopicEntryBottomSheet(
          context: context,
          subject: subject,
          topic: topic.topic,
          subjectDisplayName: displayName,
          topicDisplayName: topic.displayName,
          availableQuestionCount: topic.questionCount,
          onTestSessionCreated: (id) => context.push('/test/$id'),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                color: isWeak ? AppColors.wrong : AppColors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              topic.displayName,
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _TopicLabeledLine(
                              label: 'Accuracy',
                              child: notStarted
                                  ? Text(
                                      'Not started',
                                      style: AppTextStyles.caption().copyWith(
                                        color: scheme.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    )
                                  : Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: [
                                        AccuracyPercentageText(
                                          attemptCount: topic.attemptCount,
                                          accuracyPercent: topic.accuracyPercent,
                                          tier: topic.accuracyTier,
                                        ),
                                        Text(
                                          '· ${topic.attemptCount} ${topic.attemptCount == 1 ? 'attempt' : 'attempts'}',
                                          style: AppTextStyles.caption()
                                              .copyWith(
                                            color: scheme.onSurfaceVariant,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _TopicLabeledLine(
                              label: 'Danger zone',
                              child: Text(
                                'Sure ${topic.dangerSureWrongLast30} · '
                                'Educated guess ${topic.dangerEducatedGuessWrongLast30} (30 days)',
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const _ActionButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Practice',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
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
              'Could not load topics.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('Retry', style: AppTextStyles.label()),
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
            Icon(Icons.topic_outlined, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No topics found for this subject.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'If your question bank is still installing, go back and try again in a moment.',
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
