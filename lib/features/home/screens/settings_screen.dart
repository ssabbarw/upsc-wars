import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/prelims_countdown.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/services/prelims_surfaces_refresh.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/theme/dark_mode_toggle.dart';

/// Play Store listing (Android package from `android/app/build.gradle.kts`).
const _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=practice.upsc.indiaapps.com.upscmcqpractice';

const _kFeedbackEmail = 'upscwars@gmail.com';
const _kTelegramDirect = 'https://t.me/upsc_wars_sachin';
const _kTelegramGroup = 'https://t.me/upsc_wars_group';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl + bottomInset,
          ),
          children: [
            _SettingsIntroBanner(isDark: isDark),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              icon: Icons.palette_rounded,
              label: 'Appearance',
              scheme: scheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _DarkModeToggleCard(),
            const SizedBox(height: AppSpacing.sm),
            const _ConfidenceTrackingCard(),
            const SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              icon: Icons.notifications_active_rounded,
              label: 'Stay in rhythm',
              scheme: scheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _PrelimsPersistentNotificationCard(),
            const SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              icon: Icons.star_rounded,
              label: 'Spread the word',
              scheme: scheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            _RateReviewCard(scheme: scheme),
            const SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              icon: Icons.forum_rounded,
              label: 'Talk to us',
              scheme: scheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FeedbackCard(scheme: scheme),
            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.xxl),
              _SectionHeader(
                icon: Icons.analytics_outlined,
                label: 'Internal',
                scheme: scheme,
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                title: Text('Feature health', style: AppTextStyles.label()),
                subtitle: Text(
                  'Local usage aggregates (SQLite)',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/internal/feature-health'),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Built with care for every serious aspirant.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIntroBanner extends StatelessWidget {
  const _SettingsIntroBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDeep,
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.primaryDeep,
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryDark,
                  AppColors.primaryDeep,
                ],
        ),
      ),
      child: Text(
        'Quiet tweaks, loud support — shape how UPSC Wars feels for you.',
        style: AppTextStyles.bodySm().copyWith(
          color: Colors.white.withValues(alpha: 0.95),
          height: 1.45,
          shadows: const [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceTrackingCard extends ConsumerWidget {
  const _ConfidenceTrackingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref.watch(prefsServiceProvider).when(
          data: (prefs) {
            return Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                value: prefs.confidenceTrackingEnabled,
                onChanged: (v) async {
                  final s = await ref.read(prefsServiceProvider.future);
                  s.confidenceTrackingEnabled = v;
                  ref.invalidate(prefsServiceProvider);
                },
                secondary: Icon(
                  Icons.psychology_alt_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
                title: Text('Confidence before reveal', style: AppTextStyles.label()),
                subtitle: Text(
                  'When on, the app asks how sure you are on important questions '
                  'before showing the answer — powers Danger Zone insights.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const SizedBox.shrink(),
        );
  }
}

class _DarkModeToggleCard extends ConsumerWidget {
  const _DarkModeToggleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref.watch(prefsServiceProvider).when(
          data: (prefs) {
            return Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                value: prefs.darkModeEnabled,
                onChanged: (v) async {
                  await setDarkModeEnabledWithLoader(
                    context: context,
                    ref: ref,
                    darkModeEnabled: v,
                  );
                },
                secondary: Icon(
                  prefs.darkModeEnabled
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
                title: Text('Dark mode', style: AppTextStyles.label()),
                subtitle: Text(
                  'Match the app to your room and late-night sessions.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const SizedBox.shrink(),
        );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm().copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RateReviewCard extends StatelessWidget {
  const _RateReviewCard({required this.scheme});

  final ColorScheme scheme;

  Future<void> _openStore(BuildContext context) async {
    await HapticFeedback.lightImpact();
    final url = Platform.isIOS
        ? 'https://apps.apple.com/search?term=${Uri.encodeComponent('UPSC Wars')}'
        : _kPlayStoreUrl;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not open the store. Try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openStore(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                scheme.surface,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (_) => const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Rate & review',
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A thirty-second review is oxygen for a solo dev. '
                'Tell the Play Store what clicked — brutal honesty welcome, warm fuzzies even more.',
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: () => _openStore(context),
                icon: const Icon(Icons.storefront_rounded, size: 22),
                label: Text(Platform.isIOS ? 'Find us on the App Store' : 'Open Play Store listing'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.scheme});

  final ColorScheme scheme;

  Future<void> _launch(BuildContext context, Uri uri) async {
    await HapticFeedback.selectionClick();
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mailUri = Uri(
      scheme: 'mailto',
      path: _kFeedbackEmail,
      queryParameters: {
        'subject': 'UPSC Wars — feedback',
        'body': 'Hi,\n\n',
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send feedback',
                  style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bug, idea, roast, or “this feature saved my mock”? '
                  'I read every message — pick the lane that feels fastest.',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _FeedbackTile(
            icon: Icons.mark_email_unread_outlined,
            iconBg: AppColors.infoBg,
            iconColor: AppColors.info,
            title: 'Email',
            subtitle: _kFeedbackEmail,
            hint: 'Best for long context, screenshots, or attachments',
            onTap: () => _launch(context, mailUri),
          ),
          const Divider(height: 1),
          _FeedbackTile(
            icon: Icons.send_rounded,
            iconBg: AppColors.infoBg,
            iconColor: AppColors.info,
            title: 'Telegram — direct',
            subtitle: 't.me/upsc_wars_sachin',
            hint: 'Quick ping, voice notes, “this broke today”',
            onTap: () => _launch(context, Uri.parse(_kTelegramDirect)),
          ),
          const Divider(height: 1),
          _FeedbackTile(
            icon: Icons.groups_2_rounded,
            iconBg: AppColors.primaryLight,
            iconColor: AppColors.primaryDark,
            title: 'Telegram — group',
            subtitle: 't.me/upsc_wars_group',
            hint: 'Crowd wisdom, peer energy, battle banter',
            onTap: () => _launch(context, Uri.parse(_kTelegramGroup)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Text(
              'Average response: human, not bot — bear with spikes on prelims week.',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: scheme.primary.withValues(alpha: 0.08),
        highlightColor: scheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label().copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrelimsPersistentNotificationCard extends ConsumerWidget {
  const _PrelimsPersistentNotificationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    if (!Platform.isAndroid) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_active_outlined, color: scheme.primary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'The ambient Prelims strip in your status bar is an Android-only flourish for now.',
                style: AppTextStyles.bodyMd().copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return ref.watch(prefsServiceProvider).when(
      data: (prefs) {
        final enabled = prefs.prelimsPersistentNotificationEnabled;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prelims reminder',
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A quiet, persistent nudge in your status bar that keeps the '
                'days-until-Prelims count in sight, calmly and continuously. '
                'Let it be your pocket-sized motivation: fewer aimless unlocks, '
                'a faster pull back to the desk—each time the screen wakes in your hand.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Show in status bar', style: AppTextStyles.label()),
                subtitle: Text(
                  'Low priority · No sound or vibration',
                  style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
                ),
                value: enabled,
                onChanged: (v) async {
                  final s = await ref.read(prefsServiceProvider.future);
                  s.prelimsPersistentNotificationEnabled = v;
                  ref.invalidate(prefsServiceProvider);
                  await PrelimsSurfacesRefresh.refreshAllSurfaces();
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                enabled ? 'Preview' : 'Preview (dimmed while off)',
                style: AppTextStyles.labelSm().copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Opacity(
                opacity: enabled ? 1 : 0.5,
                child: const _AndroidPrelimsNotificationPreview(),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _AndroidPrelimsNotificationPreview extends StatelessWidget {
  const _AndroidPrelimsNotificationPreview();

  @override
  Widget build(BuildContext context) {
    final title = PrelimsCountdown.persistentNotificationTitle();
    final body = PrelimsCountdown.persistentNotificationBody();
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xFF26211C),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary,
                    Color.lerp(primary, Colors.black, 0.22)!,
                  ],
                ),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPSC Wars',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
