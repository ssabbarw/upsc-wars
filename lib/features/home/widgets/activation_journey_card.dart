import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../providers/home_activation_journey_provider.dart';
import 'get_started_card.dart';
import '../../../l10n/l10n.dart';

/// START HERE — cold-start card until the demo test is done.
class ActivationJourneyCard extends HookConsumerWidget {
  const ActivationJourneyCard({super.key, required this.state});

  final HomeActivationJourneyState state;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(openGetStartedFromHome(context, ref)),
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
                  if (state.canSnoozeChecklist)
                    GestureDetector(
                      onTap: () => unawaited(
                        showActivationJourneySnoozeSheet(context, ref),
                      ),
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
                          ? context.l10n.activationLeftAt(state.demoInProgressDone, state.demoInProgressTotal)
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
                  onPressed: () =>
                      unawaited(openGetStartedFromHome(context, ref)),
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

