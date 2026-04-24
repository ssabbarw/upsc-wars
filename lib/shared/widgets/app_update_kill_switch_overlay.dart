import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upsc_wars/shared/widgets/contact_us_entry.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_toast.dart';

/// Full-screen, non-dismissable scrim + compact bottom sheet (kill switch).
class AppUpdateKillSwitchOverlay extends StatelessWidget {
  const AppUpdateKillSwitchOverlay({super.key});

  String _iosSearchFallback() =>
      'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConstants.appDisplayName)}';

  Future<void> _openUrl(BuildContext context, String url) async {
    await HapticFeedback.lightImpact();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.showText(context, 'Could not open the store.');
    }
  }

  String _storeUrl() {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    if (ios) {
      final u = AppConstants.appStoreUrl.trim();
      if (u.isNotEmpty) return u;
      return _iosSearchFallback();
    }
    return AppConstants.playStoreUrl.trim();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final url = _storeUrl();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: ColoredBox(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md + bottom,
                ),
                child: Material(
                  color: scheme.surfaceContainerHigh,
                  elevation: 2,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Update required',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h3().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'This version is no longer supported.\n Kindly Update to keep practicing.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: url.isEmpty
                              ? null
                              : () => _openUrl(context, url),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            url.isEmpty ? 'Store link missing' : 'Update',
                            style: AppTextStyles.label().copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                        if (url.isEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Set app store URLs in app constants.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Update from the store to continue',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                        ContactUsTextButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
