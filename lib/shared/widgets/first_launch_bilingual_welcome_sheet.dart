import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Welcome sheet: Hindi + English copy; warm layout. Shown on each app open
/// while testing (caller decides frequency).
Future<void> showFirstLaunchBilingualWelcomeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final maxH = MediaQuery.sizeOf(sheetContext).height * 0.88;

      final warmTop = Color.lerp(
        isDark ? AppColors.surfaceSecondaryDark : AppColors.warningBg,
        isDark ? AppColors.primaryDeep : AppColors.primaryLight,
        isDark ? 0.35 : 0.5,
      )!;
      final warmBottom = scheme.surfaceContainerHighest;
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
          child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Material(
                color: scheme.surface,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.45),
                    ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [warmTop, warmBottom],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.35,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: scheme.surface.withValues(
                                      alpha: isDark ? 0.2 : 0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.waving_hand_rounded,
                                    size: 32,
                                    color: isDark
                                        ? AppColors.warning
                                        : AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome · स्वागत है',
                                        style: AppTextStyles.h3().copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Glad you are here',
                                        style: AppTextStyles.label().copyWith(
                                          color: scheme.onSurfaceVariant,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LangBlock(
                                label: 'English',
                                icon: Icons.abc_rounded,
                                scheme: scheme,
                                isDark: isDark,
                                body:
                                    'We are really happy to have you here. Every '
                                    'question in the app is available in Hindi and '
                                    'English. On any question screen, use the '
                                    'English / Hindi toggle to switch languages '
                                    'whenever you like.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _LangBlock(
                                label: 'हिन्दी',
                                icon: Icons.translate_rounded,
                                scheme: scheme,
                                isDark: isDark,
                                body:
                                    'आपका स्वागत है। ऐप में मौजूद हर प्रश्न हिंदी '
                                    'और अंग्रेज़ी दोनों में उपलब्ध है। किसी भी '
                                    'प्रश्न वाली स्क्रीन पर अंग्रेज़ी / हिंदी टॉगल '
                                    'से आप कभी भी भाषा बदल सकते हैं।',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg + 2,
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            shadowColor: AppColors.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          child: Text(
                            "Let's go!",
                            style: AppTextStyles.h3().copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      );
    },
  );
}

class _LangBlock extends StatelessWidget {
  const _LangBlock({
    required this.label,
    required this.icon,
    required this.scheme,
    required this.isDark,
    required this.body,
  });

  final String label;
  final IconData icon;
  final ColorScheme scheme;
  final bool isDark;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurface,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
