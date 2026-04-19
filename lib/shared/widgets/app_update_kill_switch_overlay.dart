import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Full-screen, non-dismissable layer: blurred dimmed backdrop + bottom sheet
/// prompting a store update (kill switch).
class AppUpdateKillSwitchOverlay extends StatelessWidget {
  const AppUpdateKillSwitchOverlay({super.key});

  String _iosSearchFallback() =>
      'https://apps.apple.com/search?term=${Uri.encodeComponent('UPSC Wars')}';

  Future<void> _openUrl(BuildContext context, String url) async {
    await HapticFeedback.mediumImpact();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Could not open the store. Try again in a browser.'),
        ),
      );
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

  String _storeLabel() {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'Open the App Store'
        : 'Open the Play Store';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final url = _storeUrl();

    return Material(
      color: Colors.transparent,
      child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Material(
                    color: scheme.surface,
                    elevation: 24,
                    shadowColor: Colors.black45,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl + bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withValues(alpha: 0.75),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.rocket_launch_rounded,
                                  color: AppColors.onPrimary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This build is behind the line.',
                                      style: AppTextStyles.h3().copyWith(
                                        color: scheme.onSurface,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'The store now carries a newer UPSC Wars — policy, polish, and prep flow all moved forward. Update to rejoin the drill room.',
                                      style: AppTextStyles.bodySm().copyWith(
                                        color: scheme.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_moon_outlined,
                                  size: 20,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Practice stays paused here until you update — your streak and data are safe on your account.',
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton.icon(
                            onPressed: url.isEmpty
                                ? null
                                : () => _openUrl(context, url),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            icon: Icon(
                              defaultTargetPlatform == TargetPlatform.iOS
                                  ? Icons.apple
                                  : Icons.shop_2_outlined,
                              size: 22,
                            ),
                            label: Text(
                              url.isEmpty
                                  ? 'Store link not configured'
                                  : _storeLabel(),
                              style: AppTextStyles.label().copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          if (url.isEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Add your store URL in app constants, then ship a new build.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'This window cannot be dismissed — updating is the only way forward.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.85,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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
