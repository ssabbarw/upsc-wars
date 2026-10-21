import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prelims_countdown.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/app_bootstrap.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prelims_date_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import '../providers/home_activation_provider.dart';
import '../providers/home_activation_journey_provider.dart';
import '../providers/daily_drill_provider.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../../daily_war/providers/daily_war_providers.dart';
import '../../practice_tests/data/practice_demo_seed.dart';
import '../../practice_tests/providers/practice_catalog_provider.dart';
import '../../practice_tests/widgets/practice_season_notice.dart';
import '../widgets/today_queue_strip.dart';
import '../providers/today_hub_provider.dart';
import '../providers/today_hero_intent_provider.dart';
import '../domain/daily_streak_service.dart';
import '../domain/today_hero.dart';
import '../../../shared/widgets/push_denied_banner.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_update_kill_switch_overlay.dart';
import '../../../shared/widgets/content_language_picker.dart';
import '../../../shared/widgets/prelims_countdown_card.dart';
import '../../../shared/widgets/soft_update_banner.dart';
import '../widgets/daily_rituals_intro_sheet.dart';
import '../widgets/data_restore_banner.dart';
import '../../../l10n/l10n.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key, this.heroSlot});

  /// Optional pin from `/?hero=` (reminder / prepare-style War FCM).
  final TodaySlotId? heroSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final home = ref.watch(homeStateProvider);
    final authState = ref.watch(authStateChangesProvider);
    final bootstrap = ref.watch(appBootstrapProvider);
    final killSwitchAsync = ref.watch(killSwitchProvider);
    final killBlocked = killSwitchAsync.maybeWhen(
      data: (s) => s.isActive,
      orElse: () => false,
    );
    final cachedStreakText = useState<String?>(null);

    useEffect(() {
      if (heroSlot == null) return null;
      TodayHeroIntentStore.capture(heroSlot!);
      return null;
    }, [heroSlot]);

    // The streak is earned by closing a Today ring, not by opening the app, so
    // this only refreshes what home shows.
    useEffect(() {
      Future(() async {
        ref.invalidate(homeStateProvider);
        ref.invalidate(homeActivationProvider);
        ref.invalidate(homeActivationJourneyProvider);
        ref.invalidate(dailyDrillProvider);
      });
      return null;
    }, const []);

    useEffect(() {
      if (!kDebugMode) return null;
      Future(() async {
        final prelims =
            ref.read(prelimsDateProvider).value ?? PrelimsCountdown.prelimsDate;
        final seeded = await seedPracticeDemoAttempts(
          ref.read(userDatabaseProvider),
          prelimsDate: prelims,
        );
        if (seeded) ref.invalidate(practiceCatalogProvider);
      });
      return null;
    }, const []);

    final routeInfo = GoRouter.of(context).routeInformationProvider;
    useListenable(routeInfo);
    final onHomeRoute = routeInfo.value.uri.path == '/';
    useEffect(() {
      if (!onHomeRoute) return null;
      unawaited(() async {
        await BattleMessagingService.maybePromptSystemAfterOnboardingHome(
          context: context,
          beforeSystemPrompt: () async {
            // Onboarding already asked; only ask here if that was skipped.
            final prefs = await ref.read(prefsServiceProvider.future);
            if (prefs.languageChosen || !context.mounted) return;
            await showContentLanguageChoiceSheet(
              context: context,
              ref: ref,
              barrierDismissible: false,
              confirmLabel: context.l10n.commonContinue,
            );
          },
        );
        if (!context.mounted) return;
        unawaited(maybeShowDailyRitualsIntro(context: context, ref: ref));
      }());
      return null;
    }, [onHomeRoute]);

    useEffect(() {
      if (!onHomeRoute) return null;
      unawaited(() async {
        final prefs = await ref.read(prefsServiceProvider.future);
        final milestone = DailyStreakService.consumePendingMilestoneCelebration(
          prefs,
        );
        if (milestone == null || !context.mounted) return;
        AppToast.showText(
          context,
          milestone == 3
              ? context.l10n.homeStreak3Toast
              : context.l10n.homeStreakMilestoneToast(milestone),
        );
      }());
      return null;
    }, [onHomeRoute, home]);

    useEffect(() {
      home.whenData((h) {
        cachedStreakText.value = context.l10n.homeStreakDays(h.streakCount);
      });
      return null;
    }, [home]);

    final greeting = _greeting(context);
    final user = authState.asData?.value;
    final accountSignedIn = AuthSession.isAccountSignedIn(user);
    final rawName = user?.displayName?.trim() ?? '';
    final safeName = rawName.toLowerCase() == 'you' ? '' : rawName;
    final userName = safeName.isNotEmpty
        ? _toTitleCase(safeName)
        : (user?.email ?? 'Aspirant');
    final avatarInitials = _avatarInitials(user?.displayName);
    final avatarColors = _avatarColors(user?.displayName, isDark);
    void openProfile() {
      if (!context.mounted) return;
      context.push('/profile');
    }

    // Back is handled once for the whole shell in `_AppShell`; a listener here
    // would sit inside an [IndexedStack] branch that stays mounted and compete
    // with the visible tab's own handler.
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeStateProvider);
                ref.invalidate(homeActivationProvider);
                ref.invalidate(homeActivationJourneyProvider);
                ref.invalidate(dailyDrillProvider);
                ref.invalidate(dailyCaScheduledPaperIsLiveProvider);
                ref.invalidate(todayHubProvider);
                final warOn = await ref.read(
                  dailyWarRemoteEnabledProvider.future,
                );
                if (warOn) await refreshDailyWarHome(ref);
              },
              child: ListView(
                physics: killBlocked
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  if (bootstrap.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Material(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.homeQuestionBankUnavailable,
                                style: AppTextStyles.label().copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                context.l10n.homeQuestionBankUnavailableBody,
                                style: AppTextStyles.bodySm().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: openProfile,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: !accountSignedIn
                                  ? scheme.surfaceContainerLow
                                  : avatarColors.bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: 0.5,
                              ),
                            ),
                            child: !accountSignedIn
                                ? Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  )
                                : Builder(
                                    builder: (context) {
                                      final photo =
                                          AppConstants.customProfilePhotoUrl(
                                            user!.photoURL,
                                          );
                                      if (photo.isEmpty) {
                                        return Center(
                                          child: Text(
                                            avatarInitials,
                                            style: AppTextStyles.label()
                                                .copyWith(
                                                  color: avatarColors.fg,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        );
                                      }
                                      return ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: photo,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          memCacheWidth:
                                              (36 *
                                                      MediaQuery.devicePixelRatioOf(
                                                        context,
                                                      ))
                                                  .round(),
                                          fadeInDuration: Duration.zero,
                                          fadeOutDuration: Duration.zero,
                                          errorWidget: (context, url, error) =>
                                              Center(
                                                child: Text(
                                                  avatarInitials,
                                                  style: AppTextStyles.label()
                                                      .copyWith(
                                                        color: avatarColors.fg,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: openProfile,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final journey = ref
                                      .watch(homeActivationJourneyProvider)
                                      .asData
                                      ?.value;
                                  final journeyActive =
                                      journey?.shouldShowChecklist ?? false;
                                  final firstName = userName.split(' ').first;
                                  final title = journeyActive
                                      ? (firstName.toLowerCase() == 'aspirant'
                                            ? context.l10n.homeGreetingGeneric
                                            : context.l10n.homeGreetingNamed(
                                                firstName,
                                              ))
                                      : greeting;
                                  final subtitle = !journeyActive
                                      ? userName
                                      : (journey?.demoInProgress ?? false)
                                      ? context.l10n.homeResumeDemoTest
                                      : context.l10n.homeStartWithDemoTest;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: AppTextStyles.h2().copyWith(
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        subtitle,
                                        style: AppTextStyles.bodySm().copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await setDarkModeEnabled(
                              ref: ref,
                              darkModeEnabled: !isDark,
                            );
                          },
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: borderColor,
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      _LanguageToggle(
                        isHindi: watchAppLanguage(ref) == 'hi',
                        borderColor: borderColor,
                        onChanged: (lang) {
                          HapticFeedback.selectionClick();
                          unawaited(persistAppLanguage(ref, lang));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const PrelimsDaysInfo(),
                      const Spacer(),
                      // Trap pill — always visible, including for new users.
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _TrapPill(
                          count: home.maybeWhen(
                            data: (h) => h.revisionTrapCount,
                            orElse: () => 0,
                          ),
                          borderColor: borderColor,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final streakCount = home.maybeWhen(
                            data: (h) => h.streakCount,
                            orElse: () => 0,
                          );
                          final streakLabel = home.when(
                            data: (h) =>
                                context.l10n.homeStreakDays(h.streakCount),
                            loading: () =>
                                cachedStreakText.value ??
                                context.l10n.homeStreakDays(0),
                            error: (_, __) =>
                                cachedStreakText.value ??
                                context.l10n.homeStreakDays(0),
                          );
                          final hot = streakCount >= 3;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: hot
                                  ? AppColors.streak.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    )
                                  : scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: hot
                                    ? AppColors.streak.withValues(alpha: 0.45)
                                    : borderColor,
                                width: hot ? 1 : 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.streak,
                                  size: hot ? 18 : 16,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  streakLabel,
                                  style: AppTextStyles.caption().copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: hot
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SoftUpdateBanner(),
                  const DataRestoreBanner(),
                  const PushDeniedBanner(compact: true),
                  const SizedBox(height: AppSpacing.md),
                  const PrelimsCountdownCard(),
                  const SizedBox(height: AppSpacing.md),
                  const TodayQueueStrip(),
                  const SizedBox(height: AppSpacing.md),
                  const _BrowseTopicsCta(),
                  const SizedBox(height: AppSpacing.md),
                  _PracticeSection(borderColor: borderColor),
                  const PracticeSeasonNotice(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
        if (killBlocked) const AppUpdateKillSwitchOverlay(),
      ],
    );
  }

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    final l10n = context.l10n;
    if (h < 12) return l10n.homeGoodMorning;
    if (h < 17) return l10n.homeGoodAfternoon;
    return l10n.homeGoodEvening;
  }

  String _avatarInitials(String? displayName) {
    final cleanName = displayName?.trim() ?? '';
    if (cleanName.isEmpty) return 'A';
    final parts = cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final names = parts.toList();
    if (names.isEmpty) return 'A';
    return names.first[0].toUpperCase();
  }

  String _toTitleCase(String value) {
    if (value.isEmpty) return value;
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
    return words.join(' ');
  }

  ({Color bg, Color fg}) _avatarColors(String? displayName, bool isDark) {
    // Same dark navy as the CA card — consistent with the app's info blue.
    return isDark
        ? (bg: const Color(0xFF042C53), fg: AppColors.infoTextDark)
        : (bg: AppColors.infoText, fg: const Color(0xFFFFFFFF));
  }
}

/// Compact EN | हि switch for the home header. Changes the app and question
/// language together (same setting as Settings → Language).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.isHindi,
    required this.borderColor,
    required this.onChanged,
  });

  final bool isHindi;
  final Color borderColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget segment(String label, String lang, bool selected) {
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected ? null : () => onChanged(lang),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSm().copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [segment('EN', 'en', !isHindi), segment('हि', 'hi', isHindi)],
      ),
    );
  }
}

class _TrapPill extends StatelessWidget {
  const _TrapPill({required this.count, required this.borderColor});

  final int count;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    final bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;

    return GestureDetector(
      onTap: () => context.push('/weak-areas/traps'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 13, color: fg),
            const SizedBox(width: 3),
            Text(
              count > 0 ? context.l10n.homeTrapsCount(count) : 'Traps',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselSectionHeader extends StatelessWidget {
  const _CarouselSectionHeader({
    required this.title,
    required this.leadingIcon,
    required this.accent,
  });

  final String title;
  final IconData leadingIcon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: accent.withValues(alpha: 0.16),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: Icon(leadingIcon, size: 16, color: accent),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _PyqYearCarousel extends StatelessWidget {
  const _PyqYearCarousel({required this.borderColor, required this.years});

  final Color borderColor;
  final List<String> years;

  static const _icons = <IconData>[
    Icons.calendar_month_rounded,
    Icons.auto_stories_outlined,
    Icons.quiz_outlined,
    Icons.history_toggle_off_rounded,
    Icons.school_outlined,
    Icons.edit_note_rounded,
  ];

  static const _accents = <Color>[
    AppColors.primary,
    AppColors.info,
    AppColors.warning,
    AppColors.correct,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CarouselSectionHeader(
          title: 'PYQ by year',
          leadingIcon: Icons.timeline,
          accent: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HorizontalDiscoveryStrip(
          children: [
            for (var i = 0; i < years.length; i++) ...[
              if (i != 0) const SizedBox(width: AppSpacing.sm),
              _HomeDiscoveryCard(
                borderColor: borderColor,
                titleText: years[i],
                icon: _icons[i % _icons.length],
                accent: _accents[i % _accents.length],
                onTap: () => context.push('/pyq-year/${years[i]}'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Horizontal strip; row height follows the tallest card (no fixed outer height).
class _HorizontalDiscoveryStrip extends StatelessWidget {
  const _HorizontalDiscoveryStrip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _HomeDiscoveryCard extends StatelessWidget {
  const _HomeDiscoveryCard({
    required this.borderColor,
    required this.titleText,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final Color borderColor;
  final String titleText;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconWellFill = isDark
        ? accent.withValues(alpha: 0.22)
        : accent.withValues(alpha: 0.12);
    final iconWellBorder = accent.withValues(alpha: isDark ? 0.55 : 0.45);
    final cardFill = Color.lerp(
      scheme.surfaceContainerLow,
      accent,
      isDark ? 0.14 : 0.10,
    )!;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: 138,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardFill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconWellFill,
                  border: Border.all(color: iconWellBorder, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 30, color: accent),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                titleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.h2().copyWith(
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Practice Section (PYQ by Year above Subjects) ────────────────────────────

class _BrowseTopicsCta extends StatelessWidget {
  const _BrowseTopicsCta();

  @override
  Widget build(BuildContext context) {
    final subject = SubjectConstants.ordered.first.slug;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () =>
            context.push('/subject/${Uri.encodeComponent(subject)}/topics'),
        icon: const Icon(Icons.search),
        label: Text(context.l10n.practiceBrowseTopics),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          textStyle: AppTextStyles.label(),
        ),
      ),
    );
  }
}

class _PracticeSection extends StatelessWidget {
  const _PracticeSection({required this.borderColor});

  final Color borderColor;

  static const _pyqYears = ['2025', '2024', '2023', '2022', '2021', '2020'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PyqYearCarousel(borderColor: borderColor, years: _pyqYears),
        const SizedBox(height: AppSpacing.md),
        _SubjectGrid(borderColor: borderColor),
      ],
    );
  }
}

// ── Subject Grid ────────────────────────────────────────────────────────────────

class _SubjectGrid extends ConsumerWidget {
  const _SubjectGrid({required this.borderColor});
  final Color borderColor;

  static const _accentColors = <Color>[
    AppColors.info,
    AppColors.warning,
    AppColors.primary,
    AppColors.correct,
    AppColors.wrong,
    AppColors.info,
    AppColors.warning,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final subjectsAsync = ref.watch(subjectTestListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.homeSubjects,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        subjectsAsync.when(
          loading: () => _SubjectGridSkeleton(borderColor: borderColor),
          error: (_, _) => const SizedBox.shrink(),
          data: (subjects) => LayoutBuilder(
            builder: (context, constraints) {
              final cols = AppBreakpoints.gridColumns(constraints.maxWidth);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.55,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, i) {
                  final s = subjects[i];
                  final def = SubjectConstants.bySlug(s.subject);
                  final accent = _accentColors[i % _accentColors.length];
                  return _SubjectGridCard(
                    info: s,
                    icon: def?.materialIcon ?? Icons.school_outlined,
                    accent: accent,
                    borderColor: borderColor,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectGridCard extends ConsumerWidget {
  const _SubjectGridCard({
    required this.info,
    required this.icon,
    required this.accent,
    required this.borderColor,
  });

  final SubjectInfo info;
  final IconData icon;
  final Color accent;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Subtle tonal background
    final cardFill = Color.lerp(scheme.surface, accent, isDark ? 0.12 : 0.05);

    // Colored border matching subject accent
    final cardBorder = accent.withValues(alpha: isDark ? 0.4 : 0.2);
    final iconBg = accent.withValues(alpha: isDark ? 0.25 : 0.1);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(maybeLogPostDemoExplore(ref, surface: 'subject'));
          context.push('/subject/${Uri.encodeComponent(info.subject)}/tests');
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardFill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cardBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: (MediaQuery.sizeOf(context).shortestSide * 0.06).clamp(
                    20.0,
                    45.0,
                  ),
                  color: accent,
                ),
              ),
              const Spacer(),
              Builder(
                builder: (context) {
                  final progress = ref
                      .watch(practiceCatalogProvider)
                      .asData
                      ?.value
                      .subjectProgress[info.subject];
                  if (progress == null || progress.testsTotal == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      context.l10n.practiceTestsProgress(
                        progress.testsDone,
                        progress.testsTotal,
                      ),
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
              Text(
                info.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectGridSkeleton extends HookWidget {
  const _SubjectGridSkeleton({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final opacity = useAnimation(
      Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)),
    );
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) => Opacity(
        opacity: opacity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cols = AppBreakpoints.gridColumns(constraints.maxWidth);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.55,
              children: List.generate(
                8,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
