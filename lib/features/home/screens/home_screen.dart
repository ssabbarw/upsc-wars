import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/domain/entities/home_state.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/app_bootstrap.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/quick_practice_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import '../widgets/deferred_push_home_nudge_banner.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/app_update_kill_switch_overlay.dart';
import '../../../shared/widgets/prelims_countdown_card.dart';
import '../../../shared/widgets/quick_practice_mode_sheet.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/home_page_video_banner.dart';

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

    useEffect(() {
      Future(() async {
        final uc = await ref.read(updateStreakUseCaseProvider.future);
        await uc.execute();
        ref.invalidate(homeStateProvider);
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
    final userName = user == null
        ? 'Aspirant'
        : displayNameForViewer(
            name: _toTitleCase(user.displayName?.trim() ?? 'Aspirant'),
            viewerEmail: user.email,
            subjectEmail: user.email,
          );
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
              child: ListView(
                physics: killBlocked
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
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
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: user == null
                                  ? scheme.surfaceContainerLow
                                  : avatarBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: 0.5,
                              ),
                            ),
                            child: user == null
                                ? Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  )
                                : ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          AppConstants.profileImageUrlOrDefault(
                                            user.photoURL,
                                          ),
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
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          avatarInitials,
                                          style: AppTextStyles.label().copyWith(
                                            color: scheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: AppTextStyles.h2().copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    userName,
                                    style: AppTextStyles.bodySm().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: AppColors.streak,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              home.when(
                                data: (h) => h.streakCount == 0
                                    ? 'Start your streak'
                                    : '${h.streakCount} days',
                                loading: () =>
                                    cachedStreakText.value ??
                                    'Start your streak',
                                error: (_, __) =>
                                    cachedStreakText.value ??
                                    'Start your streak',
                              ),
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const PrelimsCountdownCard(),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: home.when(
                      data: (h) {
                        final goalDone =
                            h.dailyGoalProgress >= h.dailyGoalTarget;
                        final progress = h.dailyGoalTarget == 0
                            ? 0.0
                            : (h.dailyGoalProgress / h.dailyGoalTarget)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final barWidth = (constraints.maxWidth * 0.55)
                                .clamp(160.0, 280.0);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Today's goal",
                                  style: AppTextStyles.labelSm().copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  goalDone
                                      ? 'Goal complete!'
                                      : '${h.dailyGoalProgress} / ${h.dailyGoalTarget} questions',
                                  textAlign: TextAlign.start,
                                  style: AppTextStyles.caption().copyWith(
                                    color: goalDone
                                        ? AppColors.correct
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  width: barWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      color: AppColors.primary,
                                      backgroundColor:
                                          scheme.surfaceContainerLow,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      loading: () => past200ms.value
                          ? SizedBox(
                              height: 36,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SubjectGrid(borderColor: borderColor),
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
                          const DeferredPushHomeNudgeBanner(),
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
                  const Center(child: ContactUsTextButton()),
                  const SizedBox(height: AppSpacing.sm),
                ],
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
          'SUBJECTS',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        subjectsAsync.when(
          loading: () => _SubjectGridSkeleton(borderColor: borderColor),
          error: (_, _) => const SizedBox.shrink(),
          data: (subjects) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
          ),
        ),
      ],
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
    final cardFill = Color.lerp(
      scheme.surface,
      accent,
      isDark ? 0.12 : 0.05,
    );

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
                child: Icon(icon, size: 18, color: accent),
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
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
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
    final revisionCount = ref.watch(activeRevisionQueueCountProvider);
    final bookmarkCount = ref.watch(bookmarkCountStreamProvider);

    final revN = revisionCount.asData?.value ?? 0;
    final bmN = bookmarkCount.asData?.value ?? 0;

    final showRevision = revN >= 3;
    final showBookmarks = bmN >= 3;

    if (!showRevision && !showBookmarks) return const SizedBox.shrink();

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
        if (showRevision) ...[
          _QuickPracticeCard(
            title: 'Revise Incorrects',
            subtitle: 'Unmastered questions',
            count: revN,
            icon: Icons.replay_outlined,
            color: AppColors.wrong,
            borderColor: borderColor,
            subject: 'revision_quick',
          ),
        ],
        if (showRevision && showBookmarks)
          const SizedBox(height: AppSpacing.sm),
        if (showBookmarks) ...[
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
        final isTutor = mode == 'tutor';
        final id = await create.execute(
          SessionConfig(
            subject: subject,
            mode: isTutor ? 'learning' : 'exam',
            questionCount: 10,
            isTimed: true,
            timeLimitSecs: isTutor ? 60 : capped * kDebugSecondsPerQuestion,
            language: 'en',
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
