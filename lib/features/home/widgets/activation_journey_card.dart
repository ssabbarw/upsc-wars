import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/deferred_push_permission_sheet.dart';
import '../providers/home_activation_journey_provider.dart';
import 'get_started_card.dart';

/// START HERE — cold-start checklist for demo test + daily reminders only.
///
/// After both are done, home switches to [DangerZoneHomeNudge] instead.
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
      return null;
    }, const []);

    // Keep the reminders step reactive: re-check when notification permission
    // changes or the app resumes (e.g. user returns from system Settings).
    // Resolve the container in build — useEffect runs during initHook and
    // cannot dependOnInheritedWidget (ProviderScope.containerOf).
    final container = ProviderScope.containerOf(context);
    useEffect(() {
      void refresh() => container.invalidate(homeActivationJourneyProvider);
      BattleMessagingService.addNotificationPermissionChangeListener(refresh);
      final observer = _ReminderLifecycleObserver(onResumed: refresh);
      WidgetsBinding.instance.addObserver(observer);
      return () {
        BattleMessagingService.removeNotificationPermissionChangeListener(
          refresh,
        );
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, [container]);

    final cardFill = isDark
        ? AppColors.primaryDeep.withValues(alpha: 0.28)
        : AppColors.primaryLight;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        state.checklistCompletedCount > 0 ? 4 : 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            completedCount: state.checklistCompletedCount,
            onSnooze: state.canSnoozeChecklist
                ? () => unawaited(
                      showActivationJourneySnoozeSheet(context, ref),
                    )
                : null,
          ),
          SizedBox(height: state.todo1Done ? 6 : 8),
          _DemoStep(state: state),
          Divider(height: 1, thickness: 1, color: divider),
          _RemindersStep(state: state),
        ],
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
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ActivationJourneySnoozeSheet(),
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
                  'Hide for now?',
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We\u2019ll bring this back tomorrow.',
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
                      'Hide for now',
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
                    'Keep going',
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

class _Header extends StatelessWidget {
  const _Header({
    required this.completedCount,
    this.onSnooze,
  });

  final int completedCount;
  final VoidCallback? onSnooze;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = completedCount == 0 ? 'START HERE' : 'KEEP GOING';
    const total = HomeActivationJourneyState.checklistStepCount;
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          '$completedCount of $total',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.primaryDark.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 14,
                height: 4,
                decoration: BoxDecoration(
                  color: i < completedCount
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
        if (onSnooze != null) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: onSnooze,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Hide for now',
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

class _DemoStep extends ConsumerWidget {
  const _DemoStep({required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final done = state.todo1Done;

    if (done) {
      return const _CollapsedDoneRow(title: 'Demo test done');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ActiveBadge(index: 1),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take a demo test',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Explanations, traps & elimination — see how it works.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: () {
                        unawaited(
                          Analytics.track(
                            ref,
                            const ActivationJourneyTodoTappedEvent(
                              todoIndex: 1,
                            ),
                          ),
                        );
                        unawaited(showGetStartedDiagnosticIntroSheet(context));
                      },
                      child: Text(
                        'Let\u2019s go',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'About 5 min',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersStep extends ConsumerWidget {
  const _RemindersStep({required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = state.todo2Done;

    if (done) {
      return const _CollapsedDoneRow(title: 'Reminders on');
    }

    return _ActiveCompactStep(
      index: 2,
      title: 'Turn on daily reminders',
      subtitle: 'Stay on track for the 9pm War and daily practice.',
      ctaLabel: 'Turn on notifications',
      onCta: () => unawaited(_enableReminders(context, ref)),
    );
  }
}

Future<void> _enableReminders(BuildContext context, WidgetRef ref) async {
  // Capture before awaits — OS permission dialog can dispose the widget/ref.
  final container = ProviderScope.containerOf(context);

  await Analytics.track(
    ref,
    const ActivationJourneyTodoTappedEvent(todoIndex: 2),
  );

  if (await BattleMessagingService.notificationsAreEnabled()) {
    container.invalidate(homeActivationJourneyProvider);
    return;
  }

  // Same education sheet that used to auto-show on 2nd app open.
  if (!context.mounted) return;
  final accepted = await showDeferredPushPermissionSheet(
    context,
    source: 'activation_reminders',
  );
  if (accepted != true) {
    container.invalidate(homeActivationJourneyProvider);
    return;
  }

  try {
    final status = await BattleMessagingService.requestPushAuthorizationAndSync(
      source: 'activation_reminders',
    );
    final grantedByOs =
        status != null &&
        BattleMessagingService.notificationAuthorizationAllowsPush(status);
    final enabled = await BattleMessagingService.notificationsAreEnabled();

    // Only open Settings when still blocked after an explicit denial.
    // Avoid a race right after grant where the OS briefly reports disabled.
    if (!enabled && !grantedByOs) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
  } catch (_) {
    // Permission / FCM sync failures shouldn't crash home — refresh UI anyway.
  }

  container.invalidate(homeActivationJourneyProvider);
}

class _ReminderLifecycleObserver with WidgetsBindingObserver {
  _ReminderLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

/// Quiet Danger Zone surface after START HERE graduates.
///
/// Locked → thin progress. Unlocked → single CTA. Opened → not shown.
class DangerZoneHomeNudge extends ConsumerWidget {
  const DangerZoneHomeNudge({super.key, required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);

    if (state.todo3Unlocked) {
      final preview = state.todo3IsPreview;
      return Material(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger Zone ready',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview
                          ? 'Early read on where you’re confidently wrong.'
                          : 'Topics where you’re confidently wrong.',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: () =>
                    unawaited(_openDangerZone(context, ref, state)),
                child: Text(
                  preview ? 'Peek' : 'Open',
                  style: AppTextStyles.label().copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final remaining = state.attemptsRemainingToPreview;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => unawaited(_showDangerZoneHelpSheet(context, state)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Danger Zone',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${state.attemptsTowardPreview}/${state.previewThreshold}',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.help_outline_rounded,
                    size: 15,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: state.previewUnlockProgress,
                  minHeight: 3,
                  backgroundColor: scheme.onSurfaceVariant.withValues(
                    alpha: 0.12,
                  ),
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                remaining == 0
                    ? 'Almost there'
                    : '$remaining to go · keep practicing',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCompactStep extends StatelessWidget {
  const _ActiveCompactStep({
    required this.index,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  final int index;
  final String title;
  final String subtitle;

  /// When null, the step renders without a button (passive / self-completing).
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActiveBadge(index: index),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                if (ctaLabel != null && onCta != null) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: onCta,
                    child: Text(
                      ctaLabel!,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedDoneRow extends StatelessWidget {
  const _CollapsedDoneRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: AppTextStyles.caption().copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          height: 1,
        ),
      ),
    );
  }
}

Future<void> _openDangerZone(
  BuildContext context,
  WidgetRef ref,
  HomeActivationJourneyState state,
) async {
  await Analytics.track(
    ref,
    const ActivationJourneyTodoTappedEvent(todoIndex: 3),
  );
  await logActivationMilestoneOnce(
    ref,
    ActivationMilestones.firstDangerZoneReview,
  );
  await markActivationConfidenceMapOpened(ref);
  if (!context.mounted) return;
  final slug = state.topSubjectSlug;
  if (slug != null && slug.isNotEmpty) {
    context.push('/subject/${Uri.encodeComponent(slug)}');
  } else {
    context.go('/progress');
  }
}

Future<void> _showDangerZoneHelpSheet(
  BuildContext context,
  HomeActivationJourneyState state,
) async {
  final remaining = state.attemptsRemainingToPreview;
  final unlocked = state.todo3Unlocked;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          sheetBottomPadding(ctx, base: AppSpacing.sm),
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
                    'What is Danger Zone?',
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Where you feel sure — and still get it wrong.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DangerZoneHelpBullet(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.wrong,
                    title: 'Confident & wrong',
                    body: 'Sure / Educated guess → incorrect',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DangerZoneHelpBullet(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: AppColors.primary,
                    title: 'Guess & right',
                    body: 'Pure guess → correct',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryDeep.withValues(alpha: 0.25)
                          : AppColors.primaryLight.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: unlocked
                        ? Text(
                            'Map unlocked — open it to see these by subject.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Early read',
                                      style: AppTextStyles.label().copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${state.attemptsTowardPreview} / '
                                    '${state.previewThreshold}',
                                    style: AppTextStyles.label().copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: state.previewUnlockProgress,
                                  minHeight: 6,
                                  backgroundColor: scheme.onSurface.withValues(
                                    alpha: 0.08,
                                  ),
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                remaining == 0
                                    ? 'Full map at ${state.fullThreshold}'
                                    : '$remaining to go · full map at '
                                          '${state.fullThreshold}',
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        'Got it',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DangerZoneHelpBullet extends StatelessWidget {
  const _DangerZoneHelpBullet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title  ',
                  style: AppTextStyles.label().copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: body,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
