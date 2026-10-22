import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/providers/understand_home_dismiss_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import '../providers/home_activation_journey_provider.dart';
import 'get_started_card.dart';
import '../../../l10n/l10n.dart';

/// START HERE — cold-start card until the demo test is done.
class ActivationJourneyCard extends HookConsumerWidget {
  const ActivationJourneyCard({
    super.key,
    required this.state,
    this.onDismiss,
  });

  final HomeActivationJourneyState state;

  /// When set (Understand section), X uses two-strike dismiss instead of snooze.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loggedShown = useRef(false);

    useEffect(() {
      if (loggedShown.value) return null;
      loggedShown.value = true;
      unawaited(
        Analytics.track(
          ref,
          ActivationJourneyShownEvent(
            todo1Done: state.todo1Done,
            scoredAttempts: state.scoredAttempts,
            todo2Unlocked: state.todo3Unlocked,
          ),
        ),
      );
      unawaited(
        Analytics.track(
          ref,
          const FeatureViewedEvent(
            featureName: 'activation_journey',
            subject: 'home',
            source: 'home',
          ),
        ),
      );
      return null;
    }, const []);

    // New big-card hero style matching the home redesign.
    final bg = isDark ? const Color(0xFF0D2818) : const Color(0xFF1B4332);
    final ctaColor = AppColors.primary;
    final showClose = onDismiss != null || state.canSnoozeChecklist;

    Future<void> attemptDemo() async {
      unawaited(
        Analytics.track(
          ref,
          const DemoTestAttemptedEvent(source: 'start_here_card'),
        ),
      );
      await openGetStartedFromHome(context, ref);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(attemptDemo()),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.activationStartHere,
                    style: AppTextStyles.caption().copyWith(
                      color: ctaColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (showClose)
                    GestureDetector(
                      onTap: () {
                        if (onDismiss != null) {
                          onDismiss!();
                          return;
                        }
                        unawaited(
                          showActivationJourneySnoozeSheet(context, ref),
                        );
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.demoInProgress
                    ? context.l10n.homeResumeDemoTest
                    : context.l10n.activationTakeDemo,
                style: AppTextStyles.h1().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.demoInProgress
                    ? (state.demoInProgressTotal > 0
                          ? context.l10n.activationLeftAt(
                              state.demoInProgressDone,
                              state.demoInProgressTotal,
                            )
                          : context.l10n.activationPickUp)
                    : context.l10n.activationDemoPitch,
                style: AppTextStyles.bodySm().copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => unawaited(attemptDemo()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctaColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.demoInProgress
                            ? context.l10n.homeResumeDemoTest
                            : context.l10n.activationStartTest,
                        style: AppTextStyles.label().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
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

/// Pitch sheet before dismissing the demo card from Understand UPSC Wars.
Future<void> showDemoDismissPitchSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        const DismissOnScrimTap(child: _DemoDismissPitchSheet()),
  );
}

/// Confirm before snoozing START HERE until tomorrow.
Future<void> showActivationJourneySnoozeSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        const DismissOnScrimTap(child: _ActivationJourneySnoozeSheet()),
  );
}

class _DemoDismissPitchSheet extends ConsumerWidget {
  const _DemoDismissPitchSheet();

  static const _onboarding = 'assets/images/onboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final cardFill = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
        : const Color(0xFFF4F6F5);
    final headerFill = isDark
        ? AppColors.correctBgDark.withValues(alpha: 0.55)
        : AppColors.primaryLight;

    Future<void> checkOut() async {
      unawaited(
        Analytics.track(
          ref,
          const DemoTestAttemptedEvent(source: 'dismiss_pitch_checkout'),
        ),
      );
      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return;
      await openGetStartedFromHome(context, ref);
    }

    void dismiss() {
      dismissUnderstandHomeItem(
        ref,
        UnderstandHomeDismissKeys.demo,
        afterPersist: (prefs, newCount) {
          unawaited(
            Analytics.track(
              ref,
              DemoTestDismissedEvent(strike: newCount),
            ),
          );
        },
      );
      Navigator.pop(context);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        sheetBottomPadding(context, base: AppSpacing.sm),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _DemoPitchHeader(fill: headerFill),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.demoPitchLead,
                    style: AppTextStyles.body().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DemoPitchPointCard(
                    number: 1,
                    title: l10n.demoPitchPoint1,
                    body: l10n.demoPitchPoint1Body,
                    fill: cardFill,
                    trailing: Image.asset(
                      '$_onboarding/target.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DemoPitchPointCard(
                    number: 2,
                    title: l10n.demoPitchPoint2,
                    body: l10n.demoPitchPoint2Body,
                    fill: cardFill,
                    trailing: Icon(
                      Icons.trending_up_rounded,
                      size: 34,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.demoPitchPerQue,
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DemoPitchFeatureChip(
                        label: l10n.demoPitchFeatureRich,
                        icon: Icons.menu_book_rounded,
                        accent: RgColors.tealDeep,
                        tint: AppColors.correctBg,
                      ),
                      _DemoPitchFeatureChip(
                        label: l10n.demoPitchFeatureStatements,
                        icon: Icons.fact_check_rounded,
                        accent: RgColors.info,
                        tint: AppColors.infoBg,
                      ),
                      _DemoPitchFeatureChip(
                        label: l10n.demoPitchFeatureElimination,
                        icon: Icons.filter_alt_rounded,
                        accent: RgColors.warning,
                        tint: AppColors.warningBg,
                      ),
                      _DemoPitchFeatureChip(
                        label: l10n.demoPitchFeatureTraps,
                        icon: Icons.warning_amber_rounded,
                        accent: RgColors.wrong,
                        tint: AppColors.wrongBg,
                      ),
                      _DemoPitchFeatureChip(
                        label: l10n.demoPitchFeatureDistractors,
                        icon: Icons.psychology_alt_rounded,
                        accent: RgColors.info,
                        tint: AppColors.infoBg,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => unawaited(checkOut()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        l10n.demoPitchCheckOutArrow,
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: dismiss,
                    child: Text(
                      l10n.demoPitchDismiss,
                      style: AppTextStyles.labelSm().copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoPitchHeader extends StatelessWidget {
  const _DemoPitchHeader({required this.fill});

  final Color fill;

  static const _onboarding = 'assets/images/onboarding';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activationStartHere,
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.demoPitchTitle,
                  style: AppTextStyles.h2().copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 96,
            height: 88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    '$_onboarding/green_scene.png',
                    width: 92,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 10,
                  child: Image.asset(
                    '$_onboarding/sparkles.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPitchPointCard extends StatelessWidget {
  const _DemoPitchPointCard({
    required this.number,
    required this.title,
    required this.body,
    required this.fill,
    required this.trailing,
  });

  final int number;
  final String title;
  final String body;
  final Color fill;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.labelSm().copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

class _DemoPitchFeatureChip extends StatelessWidget {
  const _DemoPitchFeatureChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.7)
            : tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationJourneySnoozeSheet extends ConsumerWidget {
  const _ActivationJourneySnoozeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    Future<void> hide() async {
      await Analytics.track(ref, const ActivationJourneySnoozedEvent());
      await snoozeActivationJourneyUntilTomorrow(ref);
      if (context.mounted) Navigator.pop(context);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        sheetBottomPadding(context, base: AppSpacing.sm),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: borderColor.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l10n.activationHideTitle,
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.activationHideBody,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => unawaited(hide()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      context.l10n.activationHideConfirm,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.l10n.activationKeepGoing,
                    style: AppTextStyles.labelSm().copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
