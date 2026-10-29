import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../domain/practice_scope.dart';
import '../providers/practice_catalog_provider.dart';
import '../providers/practice_subject_insights_provider.dart';
import '../widgets/practice_snapshot_card.dart';
import '../widgets/practice_test_tile.dart';

/// Subject practice home: season snapshot, then that subject's tests.
class PracticeSubjectScreen extends ConsumerWidget {
  const PracticeSubjectScreen({super.key, required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(practiceCatalogProvider);
    final insights = ref.watch(practiceSubjectInsightsProvider(subject));
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final title = SubjectConstants.bySlug(subject)?.displayName ?? subject;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(practiceCatalogProvider),
            child: Text(context.l10n.commonRetry),
          ),
        ),
        data: (data) {
          final scope = PracticeScope.subject(subject);
          final tests = data.testsFor(scope);
          final progress = data.progressFor(scope);
          final firstOpen = tests.indexWhere((t) => !t.isDone);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: PracticeSnapshotCard(
                  progress: progress,
                  insights: insights,
                  ctaLabel: context.l10n.practiceSnapshotSee,
                  onCta: progress.answered == 0
                      ? null
                      : () => context.push(
                          '/subject/${Uri.encodeComponent(subject)}/insights',
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  context.l10n.practiceTabTests,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
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
                          topic: null,
                          title: title,
                          test: tests[i],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
