import 'package:flutter/material.dart';

import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Returns the selected subject slug, or `null` if dismissed.
Future<String?> showDailyDrillSubjectSheet(
  BuildContext context, {
  required String selectedSubject,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DailyDrillSubjectSheet(selectedSubject: selectedSubject),
  );
}

class _DailyDrillSubjectSheet extends StatelessWidget {
  const _DailyDrillSubjectSheet({required this.selectedSubject});

  final String selectedSubject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final options = <_SubjectOption>[
      _SubjectOption(
        slug: DailyDrillConstants.defaultSubject,
        label: displayNameForSessionSubject(DailyDrillConstants.defaultSubject),
        icon: Icons.shuffle_rounded,
      ),
      ...SubjectConstants.ordered.map(
        (s) => _SubjectOption(
          slug: s.slug,
          label: s.displayName,
          icon: s.materialIcon,
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        sheetBottomPadding(context),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: borderColor.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Daily practice subject',
                        style: AppTextStyles.h3().copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choose what your daily drill focuses on.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    itemCount: options.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option.slug == selectedSubject;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.55)
                                : borderColor.withValues(alpha: 0.35),
                          ),
                        ),
                        tileColor: selected
                            ? (isDark
                                  ? AppColors.primaryDeep.withValues(alpha: 0.22)
                                  : AppColors.primaryLight.withValues(
                                      alpha: 0.45,
                                    ))
                            : null,
                        leading: Icon(
                          option.icon,
                          color: selected
                              ? AppColors.primaryDark
                              : scheme.onSurfaceVariant,
                        ),
                        title: Text(
                          option.label,
                          style: AppTextStyles.label().copyWith(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, option.slug),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectOption {
  const _SubjectOption({
    required this.slug,
    required this.label,
    required this.icon,
  });

  final String slug;
  final String label;
  final IconData icon;
}
