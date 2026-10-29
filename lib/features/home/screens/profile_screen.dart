import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/package_info_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/services/prelims_surfaces_refresh.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/auth_provider_sign_in_button.dart';
import '../../../shared/widgets/en_hi_language_toggle.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../community/services/community_bucket_presence_service.dart';
import '../providers/auth_providers.dart';
import '../services/profile_photo_service.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final authActions = ref.watch(authActionsProvider);
    final isBusy = authActions.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (!AuthSession.isAccountSignedIn(user)) {
              return _SignedOutProfileBody(isBusy: isBusy);
            }
            return _SignedInProfileBody(user: user!, isBusy: isBusy);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _SignedOutProfileBody extends ConsumerWidget {
  const _SignedOutProfileBody({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          context.l10n.profileSignInPitch,
          style: AppTextStyles.bodySm().copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
          AuthProviderSignInButton(
            type: AuthProviderButtonType.apple,
            onPressed: isBusy
                ? null
                : () =>
                      ref.read(authActionsProvider.notifier).signInWithApple(),
            isLoading: isBusy,
            text: isBusy
                ? context.l10n.authSigningIn
                : context.l10n.authContinueApple,
          ),
          const SizedBox(height: 12),
        ],
        AuthProviderSignInButton(
          type: AuthProviderButtonType.google,
          onPressed: isBusy
              ? null
              : () => ref.read(authActionsProvider.notifier).signInWithGoogle(),
          isLoading: isBusy,
          text: isBusy
              ? context.l10n.authSigningIn
              : context.l10n.authContinueGoogle,
        ),
        const SizedBox(height: AppSpacing.xl),
        const _QuickSettingsCard(),
        const SizedBox(height: AppSpacing.xl),
        const _ProfileFooter(),
      ],
    );
  }
}

class _SignedInProfileBody extends HookConsumerWidget {
  const _SignedInProfileBody({required this.user, required this.isBusy});

  final User user;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadingPhoto = useState(false);
    final photoService = useMemoized(ProfilePhotoService.new);
    final scheme = Theme.of(context).colorScheme;
    final profileNameLabel = displayNameForViewer(
      name: user.displayName ?? user.email ?? 'Signed in user',
      viewerEmail: user.email,
      subjectEmail: user.email,
    );

    Future<void> onChangePhoto() async {
      if (uploadingPhoto.value) return;
      uploadingPhoto.value = true;
      try {
        final (ok, err) = await photoService.pickCropUploadAndUpdateProfile();
        if (!context.mounted) return;
        if (ok) {
          AppToast.showText(context, context.l10n.profilePhotoUpdated);
          unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
        } else if (err != null) {
          AppToast.showText(context, err);
        }
      } finally {
        if (context.mounted) uploadingPhoto.value = false;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TappableCircularAvatar(
                  imageUrl: user.photoURL,
                  displayName: profileNameLabel,
                  size: 56,
                ),
                if (!kIsWeb)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: scheme.surface,
                      elevation: 1,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: uploadingPhoto.value || isBusy
                            ? null
                            : onChangePhoto,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: uploadingPhoto.value
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.photo_camera_outlined,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profileNameLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? context.l10n.profileNoEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (kIsWeb) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.profilePhotoWebHint,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _QuickSettingsCard(),
        const SizedBox(height: AppSpacing.xl),
        const _ProfileFooter(),
      ],
    );
  }
}

class _QuickSettingsCard extends ConsumerWidget {
  const _QuickSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final language = watchAppLanguage(ref);
    final prefsAsync = ref.watch(prefsServiceProvider);
    final readingIndex = ReadingFontScale.indexFor(
      ref.watch(readingFontScaleProvider),
    );
    final lastReading = ReadingFontScale.steps.length - 1;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              'Quick settings',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          _QuickRow(
            icon: Icons.translate_rounded,
            title: context.l10n.settingsLanguageTitle,
            subtitle: language == 'hi'
                ? context.l10n.settingsLanguageSubtitleHi
                : context.l10n.settingsLanguageSubtitleEn,
            trailing: EnHiLanguageToggle(
              language: language,
              onChanged: (lang) =>
                  unawaited(switchAppLanguage(context, ref, lang)),
            ),
          ),
          const Divider(height: 1),
          prefsAsync.when(
            data: (prefs) => _QuickSwitchRow(
              icon: prefs.darkModeEnabled
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              title: context.l10n.settingsDarkMode,
              subtitle: context.l10n.settingsDarkModeSubtitle,
              value: prefs.darkModeEnabled,
              onChanged: (v) =>
                  unawaited(setDarkModeEnabled(ref: ref, darkModeEnabled: v)),
            ),
            loading: () => const _QuickLoadingRow(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          prefsAsync.when(
            data: (prefs) => _QuickSwitchRow(
              icon: Icons.psychology_alt_rounded,
              title: context.l10n.settingsConfidenceTitle,
              subtitle: context.l10n.settingsConfidenceSubtitle,
              value: prefs.confidenceTrackingEnabled,
              onChanged: (v) async {
                final s = await ref.read(prefsServiceProvider.future);
                s.confidenceTrackingEnabled = v;
                ref.invalidate(prefsServiceProvider);
                await Analytics.track(
                  ref,
                  ConfidenceTrackingToggledEvent(enabled: v),
                );
              },
            ),
            loading: () => const _QuickLoadingRow(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          prefsAsync.when(
            data: (prefs) {
              final android =
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
              if (!android) {
                return _QuickRow(
                  icon: Icons.notifications_active_outlined,
                  title: context.l10n.settingsStatusBarReminder,
                  subtitle: context.l10n.settingsAndroidOnly,
                );
              }
              return _QuickSwitchRow(
                icon: Icons.notifications_active_outlined,
                title: context.l10n.settingsStatusBarReminder,
                subtitle: context.l10n.settingsStatusBarReminderSubtitle,
                value: prefs.prelimsPersistentNotificationEnabled,
                onChanged: (v) async {
                  final s = await ref.read(prefsServiceProvider.future);
                  s.prelimsPersistentNotificationEnabled = v;
                  ref.invalidate(prefsServiceProvider);
                  await PrelimsSurfacesRefresh.refreshAllSurfaces();
                  if (!context.mounted) return;
                  if (v) {
                    await _showStatusBarReminderSheet(context);
                  }
                },
              );
            },
            loading: () => const _QuickLoadingRow(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          _QuickRow(
            icon: Icons.format_size_rounded,
            title: context.l10n.settingsReadingSize,
            subtitle: context.l10n.settingsReadingSizeSubtitle,
            trailing: Text(
              _readingSizeLabel(context, readingIndex),
              style: AppTextStyles.caption().copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.settingsReadingSmaller,
                  onPressed: readingIndex == 0
                      ? null
                      : () => ref
                            .read(readingFontScaleProvider.notifier)
                            .setIndex(readingIndex - 1),
                  icon: const Icon(Icons.text_decrease_rounded, size: 20),
                ),
                Expanded(
                  child: Slider(
                    value: readingIndex.toDouble(),
                    min: 0,
                    max: lastReading.toDouble(),
                    divisions: lastReading,
                    label: _readingSizeLabel(context, readingIndex),
                    onChanged: (v) => ref
                        .read(readingFontScaleProvider.notifier)
                        .setIndex(v.round()),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.settingsReadingLarger,
                  onPressed: readingIndex == lastReading
                      ? null
                      : () => ref
                            .read(readingFontScaleProvider.notifier)
                            .setIndex(readingIndex + 1),
                  icon: const Icon(Icons.text_increase_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// Shared icon column so every title starts on the same vertical line.
  static const iconSlot = 24.0;

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSlot,
            height: iconSlot,
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label()),
                Text(
                  subtitle,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _QuickSwitchRow extends StatelessWidget {
  const _QuickSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: _QuickRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: ExcludeSemantics(
          child: IgnorePointer(
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLoadingRow extends StatelessWidget {
  const _QuickLoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

Future<void> _showStatusBarReminderSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Parked in your notification drawer',
                      style: AppTextStyles.h3().copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No buzz. No “tap me now” drama. Just a quiet Prelims countdown '
                'sitting with your other notifications — like a sticky note that '
                'refuses to let D-day sneak up on you.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Pull down the shade anytime. The days-left count will be waiting.',
                style: AppTextStyles.bodySm().copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it — I’ll peek later'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _readingSizeLabel(BuildContext context, int index) {
  final l10n = context.l10n;
  return switch (index) {
    0 => l10n.readingSizeSmall,
    1 => l10n.readingSizeDefault,
    2 => l10n.readingSizeMedium,
    3 => l10n.readingSizeLarge,
    _ => l10n.readingSizeExtraLarge,
  };
}

class _ProfileFooter extends ConsumerWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.45,
    );
    final versionLabel = ref
        .watch(packageInfoProvider)
        .maybeWhen(data: appVersionLabel, orElse: () => '');
    return Column(
      children: [
        if (versionLabel.isNotEmpty) ...[
          Text(
            'Current app version: $versionLabel',
            textAlign: TextAlign.center,
            style: style,
          ),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Made with love ', style: style),
            Icon(
              Icons.favorite,
              size: 15,
              color: scheme.error.withValues(alpha: 0.9),
            ),
            Text(' in Delhi', style: style),
          ],
        ),
      ],
    );
  }
}
