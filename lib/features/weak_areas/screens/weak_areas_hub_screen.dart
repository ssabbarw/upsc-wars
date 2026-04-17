import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/user_db.dart' show UserTopicStat;
import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/revision_queue_item.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _WeakTopicGroup {
  const _WeakTopicGroup({
    required this.subject,
    required this.topic,
    required this.failureCount,
    required this.questionUuids,
    required this.accuracyPercent,
    required this.attemptPercent,
    required this.questionCount,
  });

  final String subject;
  final String topic;
  final int failureCount;
  final List<String> questionUuids;
  final double? accuracyPercent;
  final double attemptPercent;
  final int questionCount;
}

class WeakAreasHubScreen extends HookConsumerWidget {
  const WeakAreasHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final weakTopicGroups = ref.watch(weakTopicGroupsProvider);
    final selectedSubject = useState<String?>(null);

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
                  Text('Weak Areas', style: AppTextStyles.h2()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: weakTopicGroups.when(
                loading: () => _skeletonList(scheme),
                error: (e, st) =>
                    _errorWidget(() => ref.invalidate(weakTopicGroupsProvider)),
                data: (groups) {
                  final subjects = SubjectConstants.ordered
                      .map((s) => s.slug)
                      .toList(growable: false);
                  if (selectedSubject.value == null ||
                      !subjects.contains(selectedSubject.value)) {
                    selectedSubject.value = subjects.first;
                  }
                  final currentSubject = selectedSubject.value!;
                  final topicsForSubject =
                      groups.where((g) => g.subject == currentSubject).toList()
                        ..sort(
                          (a, b) => b.failureCount.compareTo(a.failureCount),
                        );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 44,
                        child: ScrollConfiguration(
                          behavior: const _NoScrollbarBehavior(),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: subjects.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final subject = subjects[i];
                              final selected = subject == currentSubject;
                              final displayName =
                                  SubjectConstants.bySlug(
                                    subject,
                                  )?.displayName ??
                                  subject;
                              return GestureDetector(
                                onTap: () => selectedSubject.value = subject,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : scheme.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : border,
                                      width: 0.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    displayName,
                                    style: AppTextStyles.labelSm().copyWith(
                                      color: selected
                                          ? AppColors.onPrimary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: topicsForSubject.isEmpty
                            ? ListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  0,
                                  AppSpacing.lg,
                                  AppSpacing.xxl,
                                ),
                                children: [
                                  Text(
                                    'Accuracy = % correct among attempted questions in the topic.\nAttempt = % of topic questions you have attempted.',
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: Text(
                                        'Attempt more questions to start seeing your weak areas for $currentSubject',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodySm().copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  0,
                                  AppSpacing.lg,
                                  AppSpacing.xxl,
                                ),
                                itemCount: topicsForSubject.length + 1,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, i) {
                                  if (i == 0) {
                                    return Text(
                                      'Accuracy = % correct among attempted questions in the topic.\nAttempt = % of topic questions you have attempted.',
                                      style: AppTextStyles.caption().copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    );
                                  }
                                  final topic = topicsForSubject[i - 1];
                                  return _TopicRow(
                                    group: topic,
                                    border: border,
                                    scheme: scheme,
                                  );
                                },
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
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.group,
    required this.border,
    required this.scheme,
  });

  final _WeakTopicGroup group;
  final Color border;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final subjectDisplayName =
        SubjectConstants.bySlug(group.subject)?.displayName ?? group.subject;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => showTestConfigBottomSheet(
          context: context,
          args: TestConfigSheetArgs(
            subject: group.subject,
            topic: group.topic,
            subjectDisplayName: subjectDisplayName,
            topicDisplayName: group.topic,
            availableQuestionCount: group.questionCount,
            topicCountWhenSubjectOnly: 0,
            onSessionCreated: (id) => context.push('/test/$id'),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.topic,
                style: AppTextStyles.bodyMd().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                'Accuracy ${_formatPercent(group.accuracyPercent)} · Attempt ${_formatPercent(group.attemptPercent)}',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final weakTopicGroupsProvider =
    FutureProvider.autoDispose<List<_WeakTopicGroup>>((ref) async {
      final items = await ref.watch(revisionQueueItemsProvider.future);
      if (items.isEmpty) return const [];

      final baseGroups = _aggregateWeakTopicGroups(items);
      final db = ref.watch(userDatabaseProvider);

      final subjects = baseGroups.map((g) => g.subject).toSet();
      final questionCountsBySubjectTopic = <String, int>{};
      final topicStatsBySubjectTopic = <String, UserTopicStat>{};

      for (final subject in subjects) {
        final countRows = await db.questionsDao
            .getTopicQuestionCountsForSubject(subject);
        for (final row in countRows) {
          questionCountsBySubjectTopic['$subject|${row.topic}'] =
              row.questionCount;
        }

        final statRows = await db.userTopicStatsDao.fetchBySubject(subject);
        for (final row in statRows) {
          topicStatsBySubjectTopic['$subject|${row.topic}'] = row;
        }
      }

      return baseGroups.map((group) {
        final key = '${group.subject}|${group.topic}';
        final questionCount = questionCountsBySubjectTopic[key] ?? 0;
        final stat = topicStatsBySubjectTopic[key];
        final totalAttempted = stat?.totalAttempted ?? 0;
        final accuracyPercent = totalAttempted > 0
            ? stat!.accuracyPercentage.clamp(0.0, 100.0)
            : null;
        final attemptPercent = questionCount > 0
            ? (totalAttempted / questionCount * 100).clamp(0.0, 100.0)
            : 0.0;

        return _WeakTopicGroup(
          subject: group.subject,
          topic: group.topic,
          failureCount: group.failureCount,
          questionUuids: group.questionUuids,
          accuracyPercent: accuracyPercent,
          attemptPercent: attemptPercent,
          questionCount: questionCount,
        );
      }).toList();
    });

List<_WeakTopicGroup> _aggregateWeakTopicGroups(List<RevisionQueueItem> items) {
  final map =
      <
        String,
        ({String subject, String topic, int failures, List<String> uuids})
      >{};
  for (final item in items) {
    final key = '${item.subject}|${item.topic}';
    final existing = map[key];
    final failureContribution =
        item.numberOfTimesAnsweredIncorrectlyInRevision + 1;
    if (existing == null) {
      map[key] = (
        subject: item.subject,
        topic: item.topic,
        failures: failureContribution,
        uuids: [item.questionUuid],
      );
    } else {
      map[key] = (
        subject: existing.subject,
        topic: existing.topic,
        failures: existing.failures + failureContribution,
        uuids: [...existing.uuids, item.questionUuid],
      );
    }
  }
  return map.values
      .map(
        (v) => _WeakTopicGroup(
          subject: v.subject,
          topic: v.topic,
          failureCount: v.failures,
          questionUuids: v.uuids,
          accuracyPercent: null,
          attemptPercent: 0,
          questionCount: 0,
        ),
      )
      .toList();
}

String _formatPercent(double? value) {
  if (value == null) return '--';
  return '${value.toStringAsFixed(1)}%';
}
