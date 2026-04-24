import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';

/// Marketing home for the Flutter web shell when the URL is not a `/share/…` link.
class WebShellLandingPage extends StatelessWidget {
  const WebShellLandingPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  static String _iosStoreUrl() {
    final u = AppConstants.appStoreUrl.trim();
    return u.isNotEmpty
        ? u
        : 'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConstants.appDisplayName)}';
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || ok) return;
    AppToast.showText(context, 'Could not open link:\n$url');
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: AppConstants.supportEmail));
    if (!context.mounted) return;
    AppToast.dismiss();
    AppToast.showText(
      context,
      'Copied ${AppConstants.supportEmail}',
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final maxW = 640.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.transparent,
        actions: [
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.primaryDeep,
                    AppColors.surfacePrimaryDark,
                    AppColors.surfaceSecondaryDark,
                  ]
                : [
                    AppColors.primaryLight,
                    AppColors.surfaceSecondaryLight,
                    AppColors.surfacePrimaryLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.35 : 0.22,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 88,
                            height: 88,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConstants.appDisplayName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1().copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.primaryDeep,
                        letterSpacing: -0.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'UPSC MCQ practice, battles, and shared test links — '
                      'built for serious prelims prep.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body().copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Get the app',
                            style: AppTextStyles.h3().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Full syllabus, streaks, battles, and bookmarks on your phone.',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          LayoutBuilder(
                            builder: (context, c) {
                              final row = c.maxWidth >= 420;
                              final play = FilledButton.icon(
                                style: WebPlayerUiTokens.primaryCta(context),
                                onPressed: () => unawaited(
                                  _openUrl(context, AppConstants.playStoreUrl),
                                ),
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 22,
                                ),
                                label: const Text('Google Play'),
                              );
                              final ios = OutlinedButton.icon(
                                style: WebPlayerUiTokens.outlineFullWidth(
                                  context,
                                ),
                                onPressed: () => unawaited(
                                  _openUrl(context, _iosStoreUrl()),
                                ),
                                icon: const Icon(Icons.apple, size: 22),
                                label: const Text('App Store'),
                              );
                              if (row) {
                                return Row(
                                  children: [
                                    Expanded(child: play),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: ios),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  play,
                                  const SizedBox(height: AppSpacing.sm),
                                  ios,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Contact us',
                            style: AppTextStyles.h3().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SelectableText(
                            AppConstants.supportEmail,
                            style: AppTextStyles.body().copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: WebPlayerUiTokens.outlineFullWidth(
                                    context,
                                  ),
                                  onPressed: () => unawaited(
                                    _openUrl(
                                      context,
                                      AppConstants.supportMailtoUri()
                                          .toString(),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.mail_outline,
                                    size: 20,
                                  ),
                                  label: const Text('Email'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: WebPlayerUiTokens.outlineFullWidth(
                                    context,
                                  ),
                                  onPressed: () =>
                                      unawaited(_copyEmail(context)),
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 20,
                                  ),
                                  label: const Text('Copy'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Community',
                            style: AppTextStyles.h3().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Updates, discussions, and support from the team.',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton.icon(
                            style: WebPlayerUiTokens.outlineFullWidth(context),
                            onPressed: () => unawaited(
                              _openUrl(
                                context,
                                AppConstants.developerTelegramUrl,
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 20),
                            label: const Text('Telegram us'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            style: WebPlayerUiTokens.outlineFullWidth(context),
                            onPressed: () => unawaited(
                              _openUrl(context, AppConstants.groupTelegramUrl),
                            ),
                            icon: const Icon(Icons.groups_2_outlined, size: 20),
                            label: const Text('Join our Telegram group'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Shared practice in the browser',
                                style: AppTextStyles.label().copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'If someone sent you a link, it should look like:',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SelectableText(
                            '…/share/test/your-share-id/',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurface,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${AppConstants.appDisplayName} · ${AppConstants.releaseVersionLabel}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.72)
            : AppColors.surfacePrimaryLight.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
