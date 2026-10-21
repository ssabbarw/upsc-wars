import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/constants/prelims_countdown.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/prelims_date_provider.dart';
import '../../../core/services/prelims_surfaces_refresh.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../../../core/constants/creator_contact.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../core/providers/super_user_provider.dart';
import '../../community/providers/user_block_providers.dart';
import '../../question_editor/widgets/question_editor_access.dart';
import '../providers/auth_providers.dart';
import '../../test_series/providers/test_series_providers.dart';
import '../../daily_ca/daily_ca_admin_constants.dart';
import '../../daily_ca/data/daily_ca_firestore.dart';
import '../../daily_ca/domain/daily_ca_generate_config.dart';
import '../../daily_ca/providers/daily_ca_admin_providers.dart';
import '../../daily_ca/widgets/daily_ca_generate_action.dart';
import '../../daily_ca/widgets/daily_ca_review_access.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/content_language_picker.dart';
import '../../../l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isSuperUser = ref.watch(isSuperUserProvider);
    final generateConfig =
        ref.watch(dailyCaGenerateConfigProvider).asData?.value ??
        DailyCaGenerateConfig.fromMap(null);
    final showQuestionEditor = canAccessQuestionEditor(
      isSuperUser: isSuperUser,
    );
    final isSignedIn = AuthSession.isAccountSignedIn(
      ref.watch(authStateChangesProvider).asData?.value,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      backgroundColor: isDark ? scheme.surface : const Color(0xFFF5F3EE),
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
              title: context.l10n.settingsSectionPreferences,
              children: const [
                _ContentLanguageTile(),
                _DarkModeTile(),
                _ReadingSizeTile(),
                _ConfidenceTrackingTile(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            const _Section(
              title: 'Prelims',
              children: [_PrelimsPersistentNotificationTile()],
            ),
            const SizedBox(height: AppSpacing.lg),

            const _MyTestSeriesSection(),

            _Section(
              title: context.l10n.settingsSectionSupport,
              children: [
                _ExternalLinkTile(
                  icon: Icons.mark_email_unread_outlined,
                  iconBg: Color(0xFFEAF1FF),
                  iconColor: Color(0xFF2F6BFF),
                  title: context.l10n.settingsSendFeedback,
                  subtitle: CreatorContact.email,
                  uriBuilder: CreatorContact.mailtoFeedbackUri,
                ),
                _ExternalLinkTile(
                  icon: Icons.send_rounded,
                  iconBg: Color(0xFFEAF1FF),
                  iconColor: Color(0xFF2F6BFF),
                  title: context.l10n.settingsTelegramDirect,
                  subtitle: 't.me/upsc_wars_sachin',
                  uriBuilder: _telegramDirectUri,
                ),
                _ExternalLinkTile(
                  icon: Icons.groups_2_rounded,
                  iconBg: Color(0xFFE8F7F0),
                  iconColor: Color(0xFF0F8F5E),
                  title: context.l10n.settingsTelegramGroup,
                  subtitle: 't.me/upsc_wars_group',
                  uriBuilder: _telegramGroupUri,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _Section(
              title: context.l10n.settingsSectionAbout,
              children: [
                _NavTile(
                  icon: Icons.info_outline_rounded,
                  iconBg: Color(0xFFF1F0FF),
                  iconColor: Color(0xFF5A43FF),
                  title: context.l10n.settingsAboutUs,
                  subtitle: context.l10n.settingsAboutUsSubtitle,
                  onTap: () => context.push('/about-us'),
                ),
                _NavTile(
                  icon: Icons.star_rate_rounded,
                  iconBg: Color(0xFFFFF4E6),
                  iconColor: Color(0xFFB25A00),
                  title: context.l10n.settingsRateApp,
                  subtitle: defaultTargetPlatform == TargetPlatform.iOS
                      ? context.l10n.settingsOpenAppStore
                      : context.l10n.settingsOpenPlayStore,
                  onTap: () => _openStore(context),
                ),
              ],
            ),

            if (kDebugMode || showQuestionEditor || isSuperUser) ...[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: isSuperUser && !kDebugMode ? 'Admin tools' : 'Internal',
                children: [
                  if (canAccessDailyCaReview(isSuperUser: isSuperUser)) ...[
                    _NavTile(
                      icon: Icons.bolt_rounded,
                      iconBg: Color(0xFFFFF4E6),
                      iconColor: Color(0xFFB25A00),
                      title: 'Pulse composer',
                      subtitle: 'Breaking news push MCQs',
                      onTap: () =>
                          context.push('/internal/fomo-pulse-composer'),
                    ),
                    if (isSuperUser)
                      _NavTile(
                        icon: Icons.smart_toy_outlined,
                        iconBg: Color(0xFFF3E8FF),
                        iconColor: Color(0xFF7C3AED),
                        title: 'LLM & API keys',
                        subtitle:
                            'Models and Anthropic keys for Shots and Daily CA',
                        onTap: () => context.push('/internal/llm-settings'),
                      ),
                    _NavTile(
                      icon: Icons.newspaper_outlined,
                      iconBg: Color(0xFFE7F0FF),
                      iconColor: Color(0xFF1D4ED8),
                      title: 'Daily CA review',
                      subtitle: 'Pick 5–10 questions and publish',
                      onTap: () => context.push(
                        DailyCaAdminConstants.reviewPath(
                          dailyCaReviewDateForNow(
                            generateHourIst: generateConfig.hourIst,
                            generateMinuteIst: generateConfig.minuteIst,
                          ),
                        ),
                      ),
                    ),
                    _NavTile(
                      icon: Icons.schedule_outlined,
                      iconBg: Color(0xFFE7F0FF),
                      iconColor: Color(0xFF1D4ED8),
                      title: 'CA generate time',
                      subtitle: generateConfig.labelIst,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: generateConfig.hourIst,
                            minute: generateConfig.minuteIst,
                          ),
                        );
                        if (picked == null) return;
                        await DailyCaFirestore.saveGenerateClock(
                          hourIst: picked.hour,
                          minuteIst: picked.minute,
                        );
                        if (context.mounted) {
                          AppToast.showText(
                            context,
                            'Generates at ${DailyCaGenerateConfig(hourIst: picked.hour, minuteIst: picked.minute).labelIst}',
                          );
                        }
                      },
                    ),
                    _NavTile(
                      icon: Icons.play_circle_outline_rounded,
                      iconBg: Color(0xFFE8F7F0),
                      iconColor: Color(0xFF0F8F5E),
                      title: 'Generate CA test',
                      subtitle: 'Run now if the scheduled draft is missing',
                      onTap: () async {
                        final date = dailyCaReviewDateForNow(
                          generateHourIst: generateConfig.hourIst,
                          generateMinuteIst: generateConfig.minuteIst,
                        );
                        final result = await confirmAndGenerateDailyCa(
                          context: context,
                          cloud: ref.read(dailyCaAdminCloudServiceProvider),
                          isoDate: date,
                        );
                        if (!context.mounted || result == null) return;
                        AppToast.showText(context, result.userMessage);
                        if (result.wroteDraft ||
                            result.reason == 'already_exists') {
                          context.push(DailyCaAdminConstants.reviewPath(date));
                        }
                      },
                    ),
                  ],
                  if (isSuperUser)
                    _NavTile(
                      icon: Icons.military_tech_outlined,
                      iconBg: Color(0xFFE8F0FF),
                      iconColor: Color(0xFF1D4ED8),
                      title: 'Static War',
                      subtitle: 'Generate, review, and publish tonight’s paper',
                      onTap: () => context.push('/internal/daily-war-admin'),
                    ),
                  if (isSuperUser)
                    _NavTile(
                      icon: Icons.sports_kabaddi_outlined,
                      iconBg: Color(0xFFEEF1F6),
                      iconColor: Color(0xFF334155),
                      title: 'Bot battles',
                      subtitle: 'People who joined or finished vs Recents bots',
                      onTap: () => context.push('/internal/bot-battles'),
                    ),
                  if (isSuperUser)
                    _NavTile(
                      icon: Icons.campaign_outlined,
                      iconBg: Color(0xFFFCEBEB),
                      iconColor: Color(0xFFC2103A),
                      title: 'Broadcast',
                      subtitle:
                          'Notify everyone — update the app or a custom message',
                      onTap: () => context.push('/internal/broadcast'),
                    ),
                  if (isSuperUser)
                    _NavTile(
                      icon: Icons.card_giftcard_rounded,
                      iconBg: Color(0xFFE1F5EE),
                      iconColor: Color(0xFF0F6E56),
                      title: 'Offer codes',
                      subtitle:
                          'Free test series codes for influencers, with limits and expiry',
                      onTap: () => context.push('/internal/test-series-promos'),
                    ),
                  if (isSuperUser)
                    _NavTile(
                      icon: Icons.html_rounded,
                      iconBg: Color(0xFFFFF4E6),
                      iconColor: Color(0xFFB25A00),
                      title: 'HTML message preview',
                      subtitle:
                          'Open the long HTML announcement as users see it',
                      onTap: () => context.push('/notification/long-html'),
                    ),
                  if (kDebugMode || isSuperUser)
                    _NavTile(
                      icon: Icons.notifications_outlined,
                      iconBg: Color(0xFFE8F0FF),
                      iconColor: Color(0xFF1D4ED8),
                      title: 'Push debug',
                      subtitle:
                          'Memory Pairs, revision game, and spot test launch',
                      onTap: () => context.push('/internal/push-debug'),
                    ),
                  if (kDebugMode)
                    _NavTile(
                      icon: Icons.analytics_outlined,
                      iconBg: Color(0xFFEEF1F6),
                      iconColor: Color(0xFF334155),
                      title: 'Feature health',
                      subtitle: 'Local usage aggregates (SQLite)',
                      onTap: () => context.push('/internal/feature-health'),
                    ),
                  if (kDebugMode)
                    _NavTile(
                      icon: Icons.notifications_active_outlined,
                      iconBg: Color(0xFFFFF4E6),
                      iconColor: Color(0xFFB25A00),
                      title: 'Spot test composer',
                      subtitle: 'Pick MCQ and send push to this device',
                      onTap: () => context.push('/internal/spot-composer'),
                    ),
                  if (kDebugMode)
                    _NavTile(
                      icon: Icons.movie_creation_outlined,
                      iconBg: Color(0xFFFFE8EC),
                      iconColor: Color(0xFFC2103A),
                      title: 'Play Store demo',
                      subtitle: 'Swipe-through promo for screen recording',
                      onTap: () => context.push('/internal/play-store-demo'),
                    ),
                  if (showQuestionEditor)
                    _NavTile(
                      icon: Icons.edit_note_outlined,
                      iconBg: Color(0xFFE8F7F0),
                      iconColor: Color(0xFF0F8F5E),
                      title: 'Question editor',
                      subtitle: 'Search, fix, and publish corrections',
                      onTap: () => context.push('/internal/question-editor'),
                    ),
                ],
              ),
            ],
            if (isSignedIn) ...[
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: context.l10n.settingsSectionPrivacy,
                children: [_BlockedUsersTile()],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: context.l10n.settingsSectionAccount,
                children: [_LogoutTile()],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const Center(child: ContactUsTextButton()),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                context.l10n.settingsFooter,
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
    AppToast.showText(context, context.l10n.settingsStoreOpenFailed);
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF18A36B),
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
                  AppConstants.appDisplayName.toUpperCase(),
                  style: AppTextStyles.labelSm().copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.settingsHeaderTagline,
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
          padding: const EdgeInsets.only(left: 8, bottom: AppSpacing.sm),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 72,
                  endIndent: AppSpacing.lg,
                  color: scheme.outlineVariant.withValues(alpha: 0.22),
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
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
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
      leading: _LeadingIcon(icon: icon, bg: iconBg, color: iconColor),
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
        vertical: 10,
      ),
    );
  }
}

/// Shown only when the user owns at least one test series.
class _MyTestSeriesSection extends ConsumerWidget {
  const _MyTestSeriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(ownedSeriesIdsProvider).asData?.value ?? const {};
    if (owned.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _Section(
          title: 'Test series',
          children: [
            _NavTile(
              icon: Icons.workspace_premium_outlined,
              iconBg: const Color(0xFFFFF4E6),
              iconColor: const Color(0xFFB25A00),
              title: 'My Test Series',
              subtitle: context.l10n.settingsSeriesUnlocked(owned.length),
              onTap: () => context.push('/my-test-series'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _BlockedUsersTile extends ConsumerWidget {
  const _BlockedUsersTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(blockedUserEmailsProvider).value?.length ?? 0;
    final subtitle = count == 0
        ? context.l10n.settingsNoOneBlocked
        : context.l10n.settingsBlockedCount(count);
    return _NavTile(
      icon: Icons.block_outlined,
      iconBg: const Color(0xFFFFE8EC),
      iconColor: const Color(0xFFC2103A),
      title: context.l10n.settingsBlockedUsers,
      subtitle: subtitle,
      onTap: () => context.push('/settings/blocked-users'),
    );
  }
}

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isBusy = ref.watch(authActionsProvider).isLoading;

    return ListTile(
      onTap: isBusy
          ? null
          : () async {
              await HapticFeedback.selectionClick();
              final shouldLogout = await _confirmLogout(context);
              if (!shouldLogout) return;
              await ref.read(authActionsProvider.notifier).signOut();
            },
      leading: const _LeadingIcon(
        icon: Icons.logout_rounded,
        bg: Color(0xFFFFE8EC),
        color: Color(0xFFC2103A),
      ),
      title: Text(
        isBusy ? context.l10n.settingsLoggingOut : context.l10n.commonLogOut,
        style: AppTextStyles.label(),
      ),
      subtitle: Text(
        context.l10n.settingsSignOutSubtitle,
        style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
    );
  }
}

Future<bool> _confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.l10n.settingsLogOutConfirmTitle),
        content: Text(context.l10n.settingsLogOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.commonLogOut),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.uriBuilder,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
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
      AppToast.showText(context, context.l10n.settingsLinkOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _launch(context),
      leading: _LeadingIcon(icon: icon, bg: iconBg, color: iconColor),
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
        vertical: 10,
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
    required this.bg,
    required this.color,
  });

  final IconData icon;
  final Color bg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ContentLanguageTile extends ConsumerWidget {
  const _ContentLanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final language = watchAppLanguage(ref);
    final isHindi = language == 'hi';

    return ListTile(
      leading: const _LeadingIcon(
        icon: Icons.translate_rounded,
        bg: Color(0xFFE1F5EE),
        color: Color(0xFF0F6E56),
      ),
      title: Text(
        context.l10n.settingsLanguageTitle,
        style: AppTextStyles.label(),
      ),
      subtitle: Text(
        isHindi
            ? context.l10n.settingsLanguageSubtitleHi
            : context.l10n.settingsLanguageSubtitleEn,
        style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      onTap: () => showContentLanguageChoiceSheet(context: context, ref: ref),
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref
        .watch(prefsServiceProvider)
        .when(
          data: (prefs) {
            return SwitchListTile(
              value: prefs.darkModeEnabled,
              onChanged: (v) async {
                await setDarkModeEnabled(ref: ref, darkModeEnabled: v);
              },
              secondary: _LeadingIcon(
                icon: prefs.darkModeEnabled
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                bg: const Color(0xFFEEF1F6),
                color: const Color(0xFF334155),
              ),
              title: Text(
                context.l10n.settingsDarkMode,
                style: AppTextStyles.label(),
              ),
              subtitle: Text(
                context.l10n.settingsDarkModeSubtitle,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
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

class _ReadingSizeTile extends ConsumerWidget {
  const _ReadingSizeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final index = ReadingFontScale.indexFor(
      ref.watch(readingFontScaleProvider),
    );
    final last = ReadingFontScale.steps.length - 1;

    void setIndex(int next) {
      if (next == index || next < 0 || next > last) return;
      HapticFeedback.selectionClick();
      ref.read(readingFontScaleProvider.notifier).setIndex(next);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LeadingIcon(
                icon: Icons.format_size_rounded,
                bg: Color(0xFFF3E8FF),
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.settingsReadingSize,
                      style: AppTextStyles.label(),
                    ),
                    Text(
                      context.l10n.settingsReadingSizeSubtitle,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                readingSizeLabel(context, index),
                style: AppTextStyles.labelSm().copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.settingsReadingSmaller,
                onPressed: index == 0 ? null : () => setIndex(index - 1),
                icon: const Icon(Icons.text_decrease_rounded, size: 22),
              ),
              Expanded(
                child: Slider(
                  value: index.toDouble(),
                  min: 0,
                  max: last.toDouble(),
                  divisions: last,
                  label: readingSizeLabel(context, index),
                  onChanged: (v) => setIndex(v.round()),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.settingsReadingLarger,
                onPressed: index == last ? null : () => setIndex(index + 1),
                icon: const Icon(Icons.text_increase_rounded, size: 22),
              ),
            ],
          ),
          const _ReadingSizePreview(),
        ],
      ),
    );
  }
}

class _ReadingSizePreview extends StatelessWidget {
  const _ReadingSizePreview();

  static const _question =
      'Which of the following statements about the Indian monsoon is correct?';
  static const _explanation =
      'The southwest monsoon reaches the Kerala coast in early June. That onset marks the usual start of the rainy season.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caption = AppTextStyles.caption().copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.settingsPreview, style: caption),
          const SizedBox(height: 8),
          Text(
            _question,
            style: context.readingFont(
              AppTextStyles.question().copyWith(color: scheme.onSurface),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _explanation,
            style: context
                .readingFont(const TextStyle(fontSize: 13, height: 1.65))
                .copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceTrackingTile extends ConsumerWidget {
  const _ConfidenceTrackingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref
        .watch(prefsServiceProvider)
        .when(
          data: (prefs) {
            return SwitchListTile(
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
              secondary: const _LeadingIcon(
                icon: Icons.psychology_alt_rounded,
                bg: Color(0xFFE8F7F0),
                color: Color(0xFF0F8F5E),
              ),
              title: Text(
                context.l10n.settingsConfidenceTitle,
                style: AppTextStyles.label(),
              ),
              subtitle: Text(
                context.l10n.settingsConfidenceSubtitle,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
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
        leading: const _LeadingIcon(
          icon: Icons.notifications_active_outlined,
          bg: Color(0xFFE8F7F0),
          color: Color(0xFF0F8F5E),
        ),
        title: Text(
          context.l10n.settingsStatusBarReminder,
          style: AppTextStyles.label(),
        ),
        subtitle: Text(
          context.l10n.settingsAndroidOnly,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
      );
    }

    return ref
        .watch(prefsServiceProvider)
        .when(
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
                    secondary: const _LeadingIcon(
                      icon: Icons.notifications_active_outlined,
                      bg: Color(0xFFE8F7F0),
                      color: Color(0xFF0F8F5E),
                    ),
                    title: Text(
                      context.l10n.settingsStatusBarReminder,
                      style: AppTextStyles.label(),
                    ),
                    subtitle: Text(
                      context.l10n.settingsStatusBarReminderSubtitle,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 10,
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

class _AndroidPrelimsNotificationPreview extends ConsumerWidget {
  const _AndroidPrelimsNotificationPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetDate =
        ref.watch(prelimsDateProvider).value ?? PrelimsCountdown.prelimsDate;
    final title = PrelimsCountdown.persistentNotificationTitle(
      targetDate: targetDate,
    );
    final body = PrelimsCountdown.persistentNotificationBody(
      targetDate: targetDate,
    );
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
                    'UPSC Prelims',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
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

String readingSizeLabel(BuildContext context, int index) {
  final l10n = context.l10n;
  return switch (index) {
    0 => l10n.readingSizeSmall,
    1 => l10n.readingSizeDefault,
    2 => l10n.readingSizeMedium,
    3 => l10n.readingSizeLarge,
    _ => l10n.readingSizeExtraLarge,
  };
}
