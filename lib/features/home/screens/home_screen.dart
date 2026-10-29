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
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import '../providers/home_activation_provider.dart';
import '../providers/home_activation_journey_provider.dart';
import '../../../core/providers/understand_home_dismiss_provider.dart';
import '../providers/daily_drill_provider.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../../daily_war/providers/daily_war_providers.dart';
import '../../practice_tests/data/practice_demo_seed.dart';
import '../../practice_tests/providers/practice_catalog_provider.dart';
import '../../practice_tests/providers/practice_subject_insights_provider.dart';
import '../../practice_tests/widgets/practice_season_notice.dart';
import '../widgets/revision_test_cards.dart';
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
import '../../../core/providers/home_page_video_provider.dart';
import '../../../shared/widgets/home_page_video_banner.dart';
import '../../../shared/widgets/prelims_countdown_card.dart';
import '../../../shared/widgets/soft_update_banner.dart';
import '../widgets/activation_journey_card.dart';
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
        final db = ref.read(userDatabaseProvider);
        final seeded = await seedPracticeDemoAttempts(db, prelimsDate: prelims);
        final backfilled = await backfillEducatedGuessCorrect(db);
        if (seeded || backfilled) {
          ref.invalidate(practiceCatalogProvider);
          ref.invalidate(practiceSubjectInsightsProvider);
        }
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
                  const SizedBox(height: AppSpacing.md),
                  const SoftUpdateBanner(),
                  const DataRestoreBanner(),
                  _RightNowSection(borderColor: borderColor),
                  const PrelimsCountdownCard(),
                  const SizedBox(height: AppSpacing.md),
                  const TodayQueueStrip(),
                  const SizedBox(height: AppSpacing.lg),
                  _PracticeUnit(borderColor: borderColor),
                  const SizedBox(height: AppSpacing.lg),
                  const RevisionTestCards(),
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

/// Home onboarding tips: push permission, promo video, and the demo START HERE.
class _RightNowSection extends ConsumerWidget {
  const _RightNowSection({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(prefsServiceProvider).asData?.value;
    final sessionHidden = ref.watch(understandHomeSessionHiddenProvider);

    // Prefer `.value` over `.asData` so a provider refresh keeps the previous
    // value — otherwise sibling items flash away with the dismissed one.
    // Session hide is applied here too so items vanish instantly (FutureProviders
    // that also watch session still lag one async tick).
    final pushEligible =
        ref.watch(pushDeniedBannerVisibleProvider).value ?? false;
    final videoPayload = ref.watch(homePageVideoVisibleProvider).value;
    final journey = ref.watch(homeActivationJourneyProvider).value;
    final demoEligible = journey?.shouldShowChecklist ?? false;

    final pushVisible =
        pushEligible &&
        !isUnderstandHomeHidden(
          prefs,
          sessionHidden,
          UnderstandHomeDismissKeys.push,
        );
    final videoVisible =
        videoPayload != null &&
        !isUnderstandHomeHidden(
          prefs,
          sessionHidden,
          UnderstandHomeDismissKeys.video(videoPayload.version),
        );
    final demoVisible =
        demoEligible &&
        !isUnderstandHomeHidden(
          prefs,
          sessionHidden,
          UnderstandHomeDismissKeys.demo,
        );

    if (!pushVisible && !videoVisible && !demoVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? scheme.surfaceContainerLow
        : Color.lerp(scheme.surface, AppColors.primary, 0.04)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.homeRightNowTitle,
              style: AppTextStyles.h2().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (pushVisible) const PushDeniedBanner(compact: true),
            if (videoVisible) ...[
              HomePageVideoBanner(borderColor: borderColor),
              if (demoVisible) const SizedBox(height: AppSpacing.sm),
            ],
            if (demoVisible && journey != null)
              ActivationJourneyCard(
                state: journey,
                onDismiss: () =>
                    unawaited(showDemoDismissPitchSheet(context, ref)),
              ),
          ],
        ),
      ),
    );
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

// ── Practice Section (PYQ by Year above Subjects) ────────────────────────────

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.commonViewAll,
                  style: AppTextStyles.labelSm().copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

/// Practice header + topic CTA + PYQ + subjects as one visual block.
class _PracticeUnit extends ConsumerWidget {
  const _PracticeUnit({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prelims =
        ref.watch(prelimsDateProvider).value ?? PrelimsCountdown.prelimsDate;
    final fill = isDark
        ? scheme.surfaceContainerLow
        : Color.lerp(scheme.surface, AppColors.primary, 0.04)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.practiceSectionTitle,
            style: AppTextStyles.h2().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.practiceSectionSubtitle(prelims.year),
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _BrowseTopicsCta(),
          const SizedBox(height: AppSpacing.lg),
          _PracticeSection(borderColor: borderColor),
        ],
      ),
    );
  }
}

class _BrowseTopicsCta extends StatelessWidget {
  const _BrowseTopicsCta();

  @override
  Widget build(BuildContext context) {
    final subject = SubjectConstants.ordered.first.slug;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/subject/${Uri.encodeComponent(subject)}/topics'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.onPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.practiceBrowseTopics,
                      style: AppTextStyles.label().copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.practiceBrowseTopicsSubtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
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
        const SizedBox(height: AppSpacing.lg),
        _SubjectList(borderColor: borderColor),
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

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Text(
                context.l10n.homePyqByYear,
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final year in years)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(year, style: AppTextStyles.label()),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/pyq-year/$year');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitleRow(
          title: context.l10n.homePyqByYear,
          onViewAll: () => _showAll(context),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var i = 0; i < years.length; i++) ...[
                if (i != 0) const SizedBox(width: AppSpacing.sm),
                _PyqYearCard(
                  year: years[i],
                  icon: _icons[i % _icons.length],
                  accent: _accents[i % _accents.length],
                  onTap: () => context.push('/pyq-year/${years[i]}'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PyqYearCard extends StatelessWidget {
  const _PyqYearCard({
    required this.year,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String year;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = Color.lerp(scheme.surface, accent, isDark ? 0.18 : 0.12)!;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: 118,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                year,
                style: AppTextStyles.h2().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.practiceQuestionCount(100),
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 4,
                width: double.infinity,
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

class _SubjectList extends ConsumerWidget {
  const _SubjectList({required this.borderColor});

  final Color borderColor;

  static const _accentColors = <Color>[
    AppColors.info,
    AppColors.warning,
    AppColors.gold,
    AppColors.primary,
    AppColors.correct,
    AppColors.wrong,
    AppColors.purple,
    AppColors.info,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectTestListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitleRow(title: context.l10n.homeSubjects),
        const SizedBox(height: AppSpacing.md),
        subjectsAsync.when(
          loading: () => const _SubjectListSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (subjects) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.35,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, i) => _SubjectCard(
              info: subjects[i],
              icon:
                  SubjectConstants.bySlug(subjects[i].subject)?.materialIcon ??
                  Icons.school_outlined,
              accent: _accentColors[i % _accentColors.length],
              borderColor: borderColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  const _SubjectCard({
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
    final progress = ref
        .watch(practiceCatalogProvider)
        .asData
        ?.value
        .subjectProgress[info.subject];

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(maybeLogPostDemoExplore(ref, surface: 'subject'));
          context.push('/subject/${Uri.encodeComponent(info.subject)}/tests');
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.gray900.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      info.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (progress != null && progress.testsTotal > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.practiceTestsProgress(
                          progress.testsDone,
                          progress.testsTotal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

class _SubjectListSkeleton extends HookWidget {
  const _SubjectListSkeleton();

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
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.35,
          children: List.generate(
            6,
            (_) => Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
