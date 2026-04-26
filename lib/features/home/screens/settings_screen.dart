import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/prelims_countdown.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/services/prelims_surfaces_refresh.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/creator_contact.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/app_toast.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
            _Header(scheme: scheme),
            const SizedBox(height: AppSpacing.lg),

            _Section(
              title: 'Preferences',
              children: const [
                _DarkModeTile(),
                _ConfidenceTrackingTile(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            const _Section(
              title: 'Prelims',
              children: [
                _PrelimsPersistentNotificationTile(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _Section(
              title: 'Support',
              children: [
                _ExternalLinkTile(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Send feedback',
                  subtitle: CreatorContact.email,
                  uriBuilder: CreatorContact.mailtoFeedbackUri,
                ),
                const _ExternalLinkTile(
                  icon: Icons.send_rounded,
                  title: 'Telegram (direct)',
                  subtitle: 't.me/upsc_wars_sachin',
                  uriBuilder: _telegramDirectUri,
                ),
                const _ExternalLinkTile(
                  icon: Icons.groups_2_rounded,
                  title: 'Telegram (group)',
                  subtitle: 't.me/upsc_wars_group',
                  uriBuilder: _telegramGroupUri,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _Section(
              title: 'About',
              children: [
                _NavTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About us',
                  subtitle: 'What we’re building, why it exists',
                  onTap: () => context.push('/about-us'),
                ),
                _NavTile(
                  icon: Icons.star_rate_rounded,
                  title: 'Rate the app',
                  subtitle: defaultTargetPlatform == TargetPlatform.iOS
                      ? 'Open App Store'
                      : 'Open Play Store',
                  onTap: () => _openStore(context),
                ),
              ],
            ),

            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: 'Internal',
                children: [
                  _NavTile(
                    icon: Icons.analytics_outlined,
                    title: 'Feature health',
                    subtitle: 'Local usage aggregates (SQLite)',
                    onTap: () => context.push('/internal/feature-health'),
                  ),
                ],
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

Future<void> _openStore(BuildContext context) async {
  await HapticFeedback.lightImpact();
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final appStore = AppConstants.appStoreUrl.trim();
  final url = ios
      ? (appStore.isNotEmpty
            ? appStore
            : 'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConstants.appDisplayName)}')
      : AppConstants.playStoreUrl;
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    AppToast.showText(context, 'Could not open the store. Try again later.');
  }
}

Uri _telegramDirectUri() => Uri.parse(CreatorContact.telegramDirectUrl);
Uri _telegramGroupUri() => Uri.parse(CreatorContact.telegramGroupUrl);

class _Header extends StatelessWidget {
  const _Header({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
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
                  scheme.primary,
                  Color.lerp(scheme.primary, Colors.black, 0.18)!,
                ],
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appDisplayName,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make the app feel like yours.',
                  style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSm().copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _CardGroup(children: children),
      ],
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () async {
        await HapticFeedback.selectionClick();
        onTap();
      },
      leading: Icon(icon, color: scheme.primary),
      title: Text(title, style: AppTextStyles.label()),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uriBuilder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Uri Function() uriBuilder;

  Future<void> _launch(BuildContext context) async {
    await HapticFeedback.selectionClick();
    final ok = await launchUrl(
      uriBuilder(),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppToast.showText(context, 'Could not open link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _launch(context),
      leading: Icon(icon, color: scheme.primary),
      title: Text(title, style: AppTextStyles.label()),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 20,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref.watch(prefsServiceProvider).when(
          data: (prefs) {
            return SwitchListTile(
              value: prefs.darkModeEnabled,
              onChanged: (v) async {
                await setDarkModeEnabled(ref: ref, darkModeEnabled: v);
              },
              secondary: Icon(
                prefs.darkModeEnabled
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: scheme.primary,
              ),
              title: Text('Dark mode', style: AppTextStyles.label()),
              subtitle: Text(
                'Comfortable contrast for long sessions.',
                style: AppTextStyles.bodySm()
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
            );
          },
          loading: () => const ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
  }
}

class _ConfidenceTrackingTile extends ConsumerWidget {
  const _ConfidenceTrackingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref.watch(prefsServiceProvider).when(
          data: (prefs) {
            return SwitchListTile(
              value: prefs.confidenceTrackingEnabled,
              onChanged: (v) async {
                final s = await ref.read(prefsServiceProvider.future);
                s.confidenceTrackingEnabled = v;
                ref.invalidate(prefsServiceProvider);
              },
              secondary: Icon(
                Icons.psychology_alt_rounded,
                color: scheme.primary,
              ),
              title: Text('Confidence before reveal', style: AppTextStyles.label()),
              subtitle: Text(
                'Ask “how sure are you?” before showing answers.',
                style: AppTextStyles.bodySm()
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
            );
          },
          loading: () => const ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
  }
}

class _PrelimsPersistentNotificationTile extends ConsumerWidget {
  const _PrelimsPersistentNotificationTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return ListTile(
        leading: Icon(Icons.notifications_active_outlined, color: scheme.primary),
        title: Text('Status bar reminder', style: AppTextStyles.label()),
        subtitle: Text(
          'Available on Android.',
          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      );
    }

    return ref.watch(prefsServiceProvider).when(
          data: (prefs) {
            final enabled = prefs.prelimsPersistentNotificationEnabled;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                children: [
                  SwitchListTile(
                    value: enabled,
                    onChanged: (v) async {
                      final s = await ref.read(prefsServiceProvider.future);
                      s.prelimsPersistentNotificationEnabled = v;
                      ref.invalidate(prefsServiceProvider);
                      await PrelimsSurfacesRefresh.refreshAllSurfaces();
                    },
                    secondary: Icon(
                      Icons.notifications_active_outlined,
                      color: scheme.primary,
                    ),
                    title: Text('Status bar reminder', style: AppTextStyles.label()),
                    subtitle: Text(
                      'Keep the days-until-Prelims count visible.',
                      style: AppTextStyles.bodySm()
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Opacity(
                        opacity: enabled ? 1 : 0.55,
                        child: const _AndroidPrelimsNotificationPreview(),
                      ),
                    ),
                    crossFadeState: enabled
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),
                ],
              ),
            );
          },
          loading: () => const ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
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
                  colors: [primary, Color.lerp(primary, Colors.black, 0.22)!],
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
                    AppConstants.appDisplayName,
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
