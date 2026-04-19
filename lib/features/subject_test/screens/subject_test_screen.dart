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
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';

class SubjectTestScreen extends HookConsumerWidget {
  const SubjectTestScreen({super.key, this.botBattleMode = false});

  final bool botBattleMode;

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
                          botBattleMode ? 'Battle setup' : 'Subject test',
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          botBattleMode
                              ? 'Choose a subject to start battle'
                              : 'Choose a subject to begin',
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
                  itemCount: subjects.length + 1,
                  separatorBuilder: (context, index) {
                    if (index == subjects.length - 1) {
                      return const SizedBox(height: AppSpacing.xl);
                    }
                    return const SizedBox(height: AppSpacing.md);
                  },
                  itemBuilder: (context, i) {
                    if (i == subjects.length) {
                      return const Center(child: ContactUsTextButton());
                    }
                    final s = subjects[i];
                    final def = SubjectConstants.bySlug(s.subject);
                    return _SubjectCard(
                      info: s,
                      icon: def?.materialIcon ?? Icons.school_outlined,
                      borderColor: borderColor,
                      onTap: () => showTestConfigBottomSheet(
                        context: context,
                        args: TestConfigSheetArgs(
                          subject: s.subject,
                          subjectDisplayName: s.displayName,
                          availableQuestionCount: s.questionCount,
                          topicCountWhenSubjectOnly: s.topicCount,
                          lockedQuestionCount: botBattleMode ? 10 : null,
                          forceExamMode: botBattleMode,
                          startButtonLabel: botBattleMode
                              ? 'Start battle'
                              : null,
                          onSessionCreated: (id) => context.push(
                            botBattleMode ? '/battle/$id' : '/test/$id',
                          ),
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
                  itemCount: 7,
                  separatorBuilder: (context, index) {
                    if (index == 5) {
                      return const SizedBox(height: AppSpacing.xl);
                    }
                    return const SizedBox(height: AppSpacing.md);
                  },
                  itemBuilder: (context, index) {
                    if (index == 6) {
                      return const Center(child: ContactUsTextButton());
                    }
                    return Container(
                      height: 96,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    );
                  },
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
                          style: AppTextStyles.body().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(subjectTestListProvider),
                          child: Text('Retry', style: AppTextStyles.label()),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const ContactUsTextButton(),
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
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${formatIntCount(info.questionCount)} questions · ${info.topicCount} topics',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
