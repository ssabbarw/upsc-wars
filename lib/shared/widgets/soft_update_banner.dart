import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_events.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/providers/soft_update_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_toast.dart';
import '../../l10n/l10n.dart';

/// Home nudge when Remote Config `soft_update_version` is ahead of this build.
class SoftUpdateBanner extends ConsumerWidget {
  const SoftUpdateBanner({super.key});

  String _storeUrl() {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    if (ios) {
      final u = AppConstants.appStoreUrl.trim();
      if (u.isNotEmpty) return u;
      return 'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConstants.appDisplayName)}';
    }
    return AppConstants.playStoreUrl.trim();
  }

  Future<void> _openStore(BuildContext context) async {
    await HapticFeedback.lightImpact();
    final url = _storeUrl();
    if (url.isEmpty) return;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppToast.showText(context, context.l10n.suStoreFailed);
    }
  }

  Future<void> _dismiss(WidgetRef ref, String version) async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.softUpdateDismissedVersion = version;
    ref.invalidate(softUpdateProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(softUpdateProvider).asData?.value;
    if (snap == null || !snap.shouldPrompt) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final version = snap.requiredMinimum?.toString() ?? '';

    return _SoftUpdateBannerBody(
      message: snap.message,
      isDark: isDark,
      scheme: scheme,
      onUpdate: () => unawaited(_openStore(context)),
      onDismiss: version.isEmpty
          ? null
          : () => unawaited(_dismiss(ref, version)),
      onShown: () {
        unawaited(
          Analytics.track(
            ref,
            const FeatureViewedEvent(
              featureName: 'soft_update_banner',
              subject: 'home',
              source: 'home',
            ),
          ),
        );
      },
    );
  }
}

class _SoftUpdateBannerBody extends StatefulWidget {
  const _SoftUpdateBannerBody({
    required this.message,
    required this.isDark,
    required this.scheme,
    required this.onUpdate,
    required this.onDismiss,
    required this.onShown,
  });

  final String message;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;
  final VoidCallback onShown;

  @override
  State<_SoftUpdateBannerBody> createState() => _SoftUpdateBannerBodyState();
}

class _SoftUpdateBannerBodyState extends State<_SoftUpdateBannerBody> {
  var _logged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logged) return;
      _logged = true;
      widget.onShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.warningBgDark : AppColors.warningBg;
    final fg = widget.isDark
        ? AppColors.warningTextDark
        : AppColors.warningText;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.system_update_alt_rounded, size: 20, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.suAvailable,
                      style: AppTextStyles.label().copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.message,
                      style: AppTextStyles.bodySm().copyWith(
                        color: widget.scheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            foregroundColor: fg,
                          ),
                          onPressed: widget.onUpdate,
                          child: Text(
                            context.l10n.suUpdate,
                            style: AppTextStyles.label().copyWith(
                              color: fg,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (widget.onDismiss != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: widget.onDismiss,
                            child: Text(
                              context.l10n.suLater,
                              style: AppTextStyles.label().copyWith(
                                color: widget.scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
