import 'package:flutter/material.dart';

import '../../core/debug/upsc_wars_trace.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Returns `true` if the user chose to open the system permission flow.
Future<bool?> showDeferredPushPermissionSheet(BuildContext context) async {
  try {
    return await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

      return PopScope(
        canPop: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            bottom + AppSpacing.sm,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              border: Border.all(color: borderColor.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withValues(
                    alpha: isDark ? 0.5 : 0.12,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Don’t let confident mistakes cost you marks again',
                    style: AppTextStyles.h3().copyWith(
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Get smart reminders for:',
                    style: AppTextStyles.body().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...[
                    'Danger Zone review',
                    'Revision queue practice',
                    'Weak topic recovery',
                    'Battle challenges',
                    'Daily Question of the Day (QOTD)',
                  ].map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              line,
                              style: AppTextStyles.body().copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Stay consistent. Recover faster. Clear prelims.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: Text(
                      'Turn on notifications',
                      style: AppTextStyles.label(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: Text(
                      'Not now',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    );
  } catch (e, st) {
    upscWarsTrace('showDeferredPushPermissionSheet', error: e, stackTrace: st);
    rethrow;
  }
}
