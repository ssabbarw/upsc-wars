import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/app_bootstrap.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/quick_practice_providers.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import '../providers/home_activation_provider.dart';
import '../providers/home_activation_journey_provider.dart';
import '../widgets/activation_journey_card.dart';
import '../providers/daily_drill_provider.dart';
import '../widgets/today_hub_section.dart';
import '../../memory_pairs/widgets/push_memory_pairs_debug_card.dart';
import '../../mini_games/widgets/push_revision_game_debug_card.dart';
import '../../push_spot_test/widgets/push_spot_test_debug_card.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../../daily_war/providers/daily_war_providers.dart';
import '../providers/today_hub_provider.dart';
import '../../daily_war/theme/daily_war_theme.dart';
import '../../../shared/widgets/push_denied_banner.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/app_update_kill_switch_overlay.dart';
import '../../../shared/widgets/prelims_countdown_card.dart';
import '../../../shared/widgets/quick_practice_mode_sheet.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/home_page_video_banner.dart';
import '../../../shared/widgets/rate_review_sheet.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

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

    final past200ms = useState(false);
    useEffect(() {
      final t = Timer(const Duration(milliseconds: 200), () {
        past200ms.value = true;
      });
      return t.cancel;
    }, const []);

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
      home.whenData((h) {
        cachedStreakText.value = h.streakCount == 0
            ? 'Start your streak'
            : '${h.streakCount} days';
      });
      return null;
    }, [home]);

    final greeting = _greeting();
    final user = authState.asData?.value;
    final accountSignedIn = AuthSession.isAccountSignedIn(user);
    final rawName = user?.displayName?.trim() ?? '';
    final safeName = rawName.toLowerCase() == 'you' ? '' : rawName;
    final userName = safeName.isNotEmpty
        ? _toTitleCase(safeName)
        : (user?.email ?? 'Aspirant');
    final avatarInitials = _avatarInitials(user?.displayName);
    final avatarBackgroundColor = _avatarBackgroundColor(
      user?.displayName,
      scheme,
    );
    void openProfile() {
      if (!context.mounted) return;
      context.push('/profile');
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (killBlocked) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Exit app?', style: AppTextStyles.h3()),
            content: Text(
              'You will leave ${AppConstants.appDisplayName}.',
              style: AppTextStyles.bodyMd(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Stack(
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
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                                  'Question bank unavailable',
                                  style: AppTextStyles.label().copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'The question database could not be opened. Reinstall the app or ensure storage is available, then restart.',
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
                              margin: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: !accountSignedIn
                                    ? scheme.surfaceContainerLow
                                    : avatarBackgroundColor,
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
                                                    color: scheme
                                                        .onPrimaryContainer,
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
                                            errorWidget:
                                                (context, url, error) => Center(
                                                  child: Text(
                                                    avatarInitials,
                                                    style: AppTextStyles.label()
                                                        .copyWith(
                                                          color: scheme
                                                              .onPrimaryContainer,
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
                                        journey?.shouldShowActivationSurface ??
                                        false;
                                    final firstName = userName.split(' ').first;
                                    final title = journeyActive
                                        ? (firstName.toLowerCase() == 'aspirant'
                                              ? 'Hey there'
                                              : 'Hey, $firstName')
                                        : greeting;
                                    final subtitle = !journeyActive
                                        ? userName
                                        : (journey!.shouldShowChecklist
                                              ? 'Two things worth doing first'
                                              : 'Your Danger Zone is building');
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
                                          style: AppTextStyles.bodySm()
                                              .copyWith(
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
                              margin: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
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
                        Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/settings'),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: borderColor,
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const PrelimsDaysInfo(),
                        const Spacer(),
                        Consumer(
                          builder: (context, ref, _) {
                            final warOn =
                                ref
                                    .watch(dailyWarRemoteEnabledProvider)
                                    .asData
                                    ?.value ??
                                false;
                            final warUnplayed =
                                warOn &&
                                (ref
                                    .watch(dailyWarHomeSnapshotProvider)
                                    .warUnplayed);
                            final streakAccent = warUnplayed
                                ? DwColors.crimson
                                : AppColors.streak;
                            // One streak, fed by any Today ring — War no longer
                            // replaces it, so a missed 9 PM is not a broken day.
                            final streakLabel = home.when(
                              data: (h) => h.streakCount == 0
                                  ? 'Start your streak'
                                  : '${h.streakCount} days',
                              loading: () =>
                                  cachedStreakText.value ?? 'Start your streak',
                              error: (error, stackTrace) =>
                                  cachedStreakText.value ?? 'Start your streak',
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: warUnplayed
                                      ? DwColors.crimson.withValues(alpha: 0.45)
                                      : borderColor,
                                  width: warUnplayed ? 1 : 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: streakAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    streakLabel,
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  if (warUnplayed) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: DwColors.crimson,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Consumer(
                      builder: (context, ref, _) {
                        final journey = ref.watch(
                          homeActivationJourneyProvider,
                        );
                        return journey.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (state) {
                            final Widget child;
                            if (state.shouldShowChecklist) {
                              child = ActivationJourneyCard(state: state);
                            } else if (state.shouldShowDangerZoneNudge) {
                              child = DangerZoneHomeNudge(state: state);
                            } else {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                    // START HERE sits above the daily loops. Keep War collapsed
                    // so the checklist still reads as the first thing to do.
                    Consumer(
                      builder: (context, ref, _) {
                        final forceCollapsed = ref
                            .watch(homeActivationJourneyProvider)
                            .maybeWhen(
                              data: (s) => s.shouldShowChecklist,
                              orElse: () => false,
                            );
                        return TodayHubSection(
                          forceWarCollapsed: forceCollapsed,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Consumer(
                      builder: (context, ref, _) {
                        final journey = ref.watch(
                          homeActivationJourneyProvider,
                        );
                        final secondary = journey.maybeWhen(
                          data: (s) => s.shouldShowActivationSurface,
                          orElse: () => false,
                        );
                        return _SubjectGrid(
                          borderColor: borderColor,
                          secondary: secondary,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    home.when(
                      loading: () {
                        if (!past200ms.value) {
                          return SizedBox(
                            height: 120,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        return _HeaderLoading(borderColor: borderColor);
                      },
                      error: (e, st) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton(
                            onPressed: () => ref.invalidate(homeStateProvider),
                            child: Text('Retry', style: AppTextStyles.label()),
                          ),
                        ],
                      ),
                      data: (h) {
                        const pyqYears = [
                          '2025',
                          '2024',
                          '2023',
                          '2022',
                          '2021',
                          '2020',
                        ];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomePageVideoBanner(borderColor: borderColor),
                            const SizedBox(height: AppSpacing.md),
                            _PyqYearCarousel(
                              borderColor: borderColor,
                              years: pyqYears,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const PushDeniedBanner(),
                            _QuickPracticeSection(borderColor: borderColor),
                            if (h.revisionTrapCount > 0) ...[
                              const SizedBox(height: AppSpacing.md),
                              _TrapPatternsCard(
                                trapCount: h.revisionTrapCount,
                                borderColor: borderColor,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Center(
                      child: ContactUsTextButton(showRateReviewCta: false),
                    ),
                    Center(
                      child: Consumer(
                        builder: (context, ref, child) {
                          return TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            onPressed: () =>
                                unawaited(showRateReviewSheet(context, ref)),
                            child: Text(
                              'Rate & review',
                              style: AppTextStyles.labelSm().copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const PushMemoryPairsDebugCard(),
                      const SizedBox(height: AppSpacing.sm),
                      const PushRevisionGameDebugCard(),
                      const SizedBox(height: AppSpacing.sm),
                      const PushSpotTestDebugCard(),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
          if (killBlocked) const AppUpdateKillSwitchOverlay(),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
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

  Color _avatarBackgroundColor(String? displayName, ColorScheme scheme) {
    final seed = displayName?.trim().toLowerCase() ?? '';
    const defaultIndex = 0;
    final palette = [
      (bg: Colors.indigo.shade100, fg: Colors.indigo.shade900),
      (bg: Colors.teal.shade100, fg: Colors.teal.shade900),
      (bg: Colors.deepOrange.shade100, fg: Colors.deepOrange.shade900),
      (bg: Colors.purple.shade100, fg: Colors.purple.shade900),
      (bg: Colors.blue.shade100, fg: Colors.blue.shade900),
      (bg: Colors.green.shade100, fg: Colors.green.shade900),
    ];
    final index = seed.isEmpty
        ? defaultIndex
        : seed.hashCode.abs() % palette.length;
    return palette[index].bg.withValues(alpha: 0.9);
  }
}

class _HeaderLoading extends HookConsumerWidget {
  const _HeaderLoading({required this.borderColor});
  final Color borderColor;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ],
    );
  }
}

class _TrapPatternsCard extends StatelessWidget {
  const _TrapPatternsCard({required this.trapCount, required this.borderColor});

  final int trapCount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => context.push('/weak-areas/traps'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trap Patterns',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "You've been caught by $trapCount trap ${trapCount == 1 ? 'type' : 'types'}",
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
            if (isWide) {
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < years.length; i++)
                    _HomeDiscoveryCard(
                      borderColor: borderColor,
                      titleText: years[i],
                      icon: _icons[i % _icons.length],
                      accent: _accents[i % _accents.length],
                      onTap: () => context.push('/pyq-year/${years[i]}'),
                    ),
                ],
              );
            }
            return _HorizontalDiscoveryStrip(
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
            );
          },
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

// ── Subject Grid ────────────────────────────────────────────────────────────────

class _SubjectGrid extends ConsumerWidget {
  const _SubjectGrid({required this.borderColor, this.secondary = false});
  final Color borderColor;
  final bool secondary;

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

    return Opacity(
      opacity: secondary ? 0.88 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            secondary ? 'PICK ANY SUBJECT' : 'SUBJECTS',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: secondary ? 0.8 : 0.6,
              fontWeight: secondary ? FontWeight.w600 : FontWeight.normal,
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
      ),
    );
  }
}

class _SubjectGridCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        onTap: () =>
            context.push('/subject/${Uri.encodeComponent(info.subject)}'),
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

// ────────────────────────────────────────────────────────────────────────────────

// ── Quick Practice Section ────────────────────────────────────────────────────

class _QuickPracticeSection extends HookConsumerWidget {
  const _QuickPracticeSection({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkCount = ref.watch(bookmarkCountStreamProvider);
    final bmN = bookmarkCount.asData?.value ?? 0;

    if (bmN < 3) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK PRACTICE',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickPracticeCard(
          title: 'Bookmarked Questions',
          subtitle: 'Questions you saved',
          count: bmN,
          icon: Icons.bookmark_outline,
          color: AppColors.info,
          borderColor: borderColor,
          subject: 'bookmarks',
        ),
      ],
    );
  }
}

class _QuickPracticeCard extends HookConsumerWidget {
  const _QuickPracticeCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.subject,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loading = useState(false);
    final capped = count.clamp(1, 10);
    final btnLabel = count >= 10
        ? 'Start 10-question test'
        : 'Start $capped-question test';
    final iconBg = isDark
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.12);

    Future<void> startSession() async {
      if (loading.value) return;
      if (!context.mounted) return;

      final mode = await showQuickPracticeModeSheet(context);
      if (mode == null) return;
      if (!context.mounted) return;

      loading.value = true;
      try {
        final create = await ref.read(createSessionUseCaseProvider.future);
        final lang = await ref.read(appLanguageProvider.future);
        final isTutor = mode == 'tutor';
        final id = await create.execute(
          SessionConfig(
            subject: subject,
            mode: isTutor ? 'learning' : 'exam',
            questionCount: 10,
            isTimed: true,
            timeLimitSecs: isTutor ? 60 : capped * kDebugSecondsPerQuestion,
            language: lang,
          ),
        );
        if (context.mounted) context.push('/test/$id');
      } finally {
        loading.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$count available',
                  style: AppTextStyles.caption().copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          loading.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : FilledButton(
                  onPressed: startSession,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(btnLabel, style: AppTextStyles.caption()),
                ),
        ],
      ),
    );
  }
}
