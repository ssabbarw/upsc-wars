import 'package:flutter/material.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../l10n/l10n.dart';

/// Explains "Revise before mock" vs "Safe areas" mock-prep cards.
void showMockPrepWhyBottomSheet(
  BuildContext context, {
  required bool isRevise,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    showDragHandle: true,
    isDismissible: true,
    builder: (ctx) {
      final padding = MediaQuery.paddingOf(ctx);
      final safeH = MediaQuery.sizeOf(ctx).height - padding.vertical;
      // Reserve space for top inset, Done button, and outer padding (~100pt).
      final maxBodyScrollHeight = (safeH - 100 - padding.bottom).clamp(
        160.0,
        640.0,
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: _MockPrepWhySheet(
          maxBodyScrollHeight: maxBodyScrollHeight,
          isRevise: isRevise,
        ),
      );
    },
  );
}

class _MockPrepWhySheet extends StatelessWidget {
  const _MockPrepWhySheet({
    required this.maxBodyScrollHeight,
    required this.isRevise,
  });

  /// Cap for the scrollable region when content is long.
  final double maxBodyScrollHeight;
  final bool isRevise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isRevise
        ? (isDark ? AppColors.warningTextDark : AppColors.warningText)
        : (isDark ? AppColors.correctTextDark : AppColors.correctText);
    final softBg = isRevise
        ? (isDark
              ? AppColors.warningBgDark.withValues(alpha: 0.4)
              : AppColors.warningBg.withValues(alpha: 0.85))
        : (isDark
              ? AppColors.correctBgDark.withValues(alpha: 0.32)
              : AppColors.correctBg.withValues(alpha: 0.65));
    final doEmoji = isRevise ? '📚' : '🎯';

    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl + 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyScrollHeight),
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                if (isRevise) ...[
                  _TitleBlock(
                    title: context.l10n.mockReviseTitle,
                    accent: accent,
                    softBg: softBg,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.mockReviseWhy,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurface,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(
                    icon: doEmoji,
                    label: context.l10n.mockWhatToDo,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.mockReviseAction,
                    style: _bodyStyle(scheme),
                  ),
                ] else ...[
                  _TitleBlock(
                    title: context.l10n.mockSafeTitle,
                    accent: accent,
                    softBg: softBg,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.mockSafeWhy,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurface,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(
                    icon: doEmoji,
                    label: context.l10n.mockWhatToDo,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(context.l10n.mockSafeAction, style: _bodyStyle(scheme)),
                ],
                const SizedBox(height: AppSpacing.xl),
                ContactUsTextButton(leadingText: context.l10n.mockMoreClarity),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              paddedBottomInset(context, AppSpacing.lg),
            ),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                context.l10n.commonDone,
                style: AppTextStyles.label().copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle _bodyStyle(ColorScheme scheme, {FontWeight? weight}) {
    return AppTextStyles.bodySm().copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
      fontWeight: weight,
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.accent,
    required this.softBg,
  });

  final String title;
  final Color accent;
  final Color softBg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyles.label().copyWith(
          color: scheme.onSurface,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final String icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
        ),
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
