import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/prefs_provider.dart';
import '../../core/review/app_review_service.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/l10n.dart';

Future<void> showRateReviewSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final maxW = MediaQuery.sizeOf(sheetContext).width;

      final content = Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW >= 700 ? 640 : 9999),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.rrTitle,
                style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                context.l10n.rrBody1,
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                context.l10n.rrBody2,
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Center(
                child: TextButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();

                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (context.mounted) {
                      context.push('/about-us');
                    }
                  },
                  child: Text(
                    context.l10n.rrJourney,
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                context.l10n.rrBody3,
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();

                    await ref
                        .read(appReviewServiceProvider)
                        .requestReviewOnce();

                    ref.invalidate(prefsServiceProvider);

                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(context.l10n.rrRate),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();

                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Text(context.l10n.commonNotNow),
                ),
              ),
            ],
          ),
        ),
      );

      return SafeArea(child: content);
    },
  );
}
