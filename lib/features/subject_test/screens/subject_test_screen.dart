import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/extensions/count_formatting.dart';
import '../../../shared/widgets/accuracy_percentage_text.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';

class SubjectTestScreen extends HookConsumerWidget {
  const SubjectTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final async = ref.watch(subjectTestListProvider);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
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
                          'Subject test',
                          style: AppTextStyles.h2()
                              .copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          'Choose a subject to begin',
                          style: AppTextStyles.bodySm()
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (subjects) => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: subjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final s = subjects[i];
                    final def = SubjectConstants.bySlug(s.subjectSlug);
                    return _SubjectCard(
                      info: s,
                      icon: def?.materialIcon ?? Icons.school_outlined,
                      borderColor: borderColor,
                      onTap: () => showTestConfigBottomSheet(
                        context: context,
                        args: TestConfigSheetArgs(
                          subjectSlug: s.subjectSlug,
                          subjectDisplayName: s.displayName,
                          availableQuestionCount: s.questionCount,
                          topicCountWhenSubjectOnly: s.topicCount,
                          onSessionCreated: (id) =>
                              context.go('/test/$id'),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: 6,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load subjects.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body()
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(subjectTestListProvider),
                          child: Text(
                            'Retry',
                            style: AppTextStyles.label(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends HookConsumerWidget {
  const _SubjectCard({
    required this.info,
    required this.icon,
    required this.borderColor,
    required this.onTap,
  });

  final SubjectInfo info;
  final IconData icon;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: scheme.onSurface),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.displayName,
                      style: AppTextStyles.label()
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${formatIntCount(info.questionCount)} questions · ${info.topicCount} topics',
                      style: AppTextStyles.bodySm()
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AccuracyPercentageText(
                      attemptCount: info.attemptCount,
                      accuracyPercent: info.accuracyPercent,
                      tier: info.accuracyTier,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
