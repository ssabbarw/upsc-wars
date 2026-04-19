import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/pyq_constants.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../providers/pyq_year_packs_provider.dart';

class PyqYearPacksScreen extends ConsumerWidget {
  const PyqYearPacksScreen({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final async = ref.watch(pyqYearPacksDataProvider(year));

    return Scaffold(
      appBar: AppBar(
        title: Text(displayNameForSessionSubject(PyqConstants.subjectSlugForYear(year))),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load PYQ sets',
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => ref.invalidate(pyqYearPacksDataProvider(year)),
                  child: Text('Retry', style: AppTextStyles.label()),
                ),
              ],
            ),
          ),
        ),
        data: (d) {
          if (d.packUuids.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'No questions are available for $year yet.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: d.packUuids.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final uuids = d.packUuids[i];
              final startQ = i * PyqConstants.questionsPerPack + 1;
              final endQ = startQ + uuids.length - 1;
              final completed = i < d.packCompleted.length && d.packCompleted[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () {
                    unawaited(
                      showTestConfigBottomSheet(
                        context: context,
                        args: TestConfigSheetArgs(
                          subject: d.subject,
                          topic: PyqConstants.packTopic(i),
                          subjectDisplayName:
                              displayNameForSessionSubject(d.subject),
                          topicDisplayName:
                              'Set ${i + 1} of ${d.packUuids.length}',
                          availableQuestionCount: uuids.length,
                          topicCountWhenSubjectOnly: 1,
                          lockedQuestionCount: uuids.length,
                          specificQuestionUuids: uuids,
                          fixedQuestionSetLabel:
                              '${uuids.length} questions (fixed order for this set)',
                          analyticsFeatureKey: 'pyq_year_pack',
                          onSessionCreated: (sessionId) async {
                            await context.push('/test/$sessionId');
                            if (context.mounted) {
                              ref.invalidate(pyqYearPacksDataProvider(year));
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test ${i + 1}',
                                style: AppTextStyles.label().copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Questions $startQ–$endQ',
                                style: AppTextStyles.bodySm().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              if (completed) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Completed',
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.correct,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (completed)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.correct,
                            size: 28,
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
