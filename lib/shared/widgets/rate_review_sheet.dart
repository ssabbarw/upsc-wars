import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/prefs_provider.dart';
import '../../core/review/app_review_service.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

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
                'Built by an Aspirant, for Aspirants',
                style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'UPSC Wars was built by an ex-UPSC aspirant who faced the same struggle of solving endless MCQs without clearly knowing where marks were actually being lost.\n\n'
                'The goal was simple: help aspirants prepare smarter by identifying confident mistakes, danger zones, safe risk areas, and better revision priorities.',
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Read about the journey and intent behind building UPSC Wars ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () async {
                          await HapticFeedback.selectionClick();
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          if (context.mounted) context.push('/about-us');
                        },
                        child: Text(
                          'here',
                          style: AppTextStyles.labelSm().copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'If the app is helping your preparation, your review can help another serious aspirant discover it too.',
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();
                    await ref.read(appReviewServiceProvider).requestReviewOnce();
                    ref.invalidate(prefsServiceProvider);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('⭐ Leave a Review'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Not now'),
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

