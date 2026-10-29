import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../domain/practice_scope.dart';
import '../providers/practice_catalog_provider.dart';
import '../widgets/practice_test_tile.dart';
import 'practice_subject_screen.dart';

class PracticeTestListScreen extends ConsumerWidget {
  const PracticeTestListScreen({super.key, required this.subject, this.topic});

  final String subject;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topic == null) {
      return PracticeSubjectScreen(subject: subject);
    }

    final scope = PracticeScope.topic(subject, topic!);
    final catalog = ref.watch(practiceCatalogProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final title = catalog.asData?.value.topicDisplayNames[topic] ?? topic!;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(practiceCatalogProvider),
            child: Text(context.l10n.commonRetry),
          ),
        ),
        data: (data) {
          final tests = data.testsFor(scope);
          final progress = data.progressFor(scope);
          final firstOpen = tests.indexWhere((t) => !t.isDone);
          final resolvedTitle = data.topicDisplayNames[topic] ?? topic!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _Header(progress: progress, borderColor: borderColor),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.go(
                    '/stats?subject=${Uri.encodeQueryComponent(subject)}',
                  ),
                  child: Text(context.l10n.practiceSeeStats),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (tests.isEmpty)
                Text(
                  context.l10n.practiceNoTests,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              for (var i = 0; i < tests.length; i++) ...[
                PracticeTestTile(
                  test: tests[i],
                  highlighted: i == firstOpen,
                  borderColor: borderColor,
                  onOpen: () => openPracticeTest(
                    context,
                    ref,
                    subject: subject,
                    topic: topic,
                    title: resolvedTitle,
                    test: tests[i],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.borderColor});

  final PracticeScopeProgress progress;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverage = progress.coveragePercent;
    final accuracy = progress.accuracyPercent;
    String pct(double? value) => value == null ? '—' : '${value.round()}%';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.practiceTestsProgress(
              progress.testsDone,
              progress.testsTotal,
            ),
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.l10n.statsCoverage(pct(coverage))}'
            ' · ${context.l10n.statsAccuracy(pct(accuracy))}',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
