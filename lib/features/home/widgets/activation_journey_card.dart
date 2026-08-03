import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import '../providers/home_activation_journey_provider.dart';
import 'get_started_card.dart';

/// START HERE activation card — matches the home onboarding mock.
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
    useEffect(() {
      void refresh() => ref.invalidate(homeActivationJourneyProvider);
      BattleMessagingService.addNotificationPermissionChangeListener(refresh);
      final observer = _ReminderLifecycleObserver(onResumed: refresh);
      WidgetsBinding.instance.addObserver(observer);
      return () {
        BattleMessagingService.removeNotificationPermissionChangeListener(
          refresh,
        );
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, const []);

    final cardFill = isDark
        ? AppColors.primaryDeep.withValues(alpha: 0.28)
        : AppColors.primaryLight;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        state.completedCount > 0 ? 6 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(completedCount: state.completedCount),
          SizedBox(height: state.todo1Done ? 8 : 14),
          _DemoStep(state: state),
          if (!state.todo1Done || !state.todo2Done)
            Divider(height: 1, thickness: 1, color: divider),
          _RemindersStep(state: state),
          if (!state.todo2Done || !state.todo3Done)
            Divider(height: 1, thickness: 1, color: divider),
          _DangerZoneStep(state: state),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.completedCount});

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    // "START HERE" only for the cold start; once step 1 is done, the user is
    // past the beginning, so switch to a progress-oriented label.
    final label = completedCount == 0 ? 'START HERE' : 'KEEP GOING';
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
          '$completedCount of 3',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.primaryDark.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ActiveBadge(index: 1),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take a demo test',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get a hang of detailed explanations, statement analysis, '
                  'traps, and elimination techniques.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
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
                        unawaited(
                          showGetStartedDiagnosticIntroSheet(context),
                        );
                      },
                      child: Text(
                        'Let\u2019s go',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
    final unlocked = state.todo2Unlocked;

    if (done) {
      return const _CollapsedDoneRow(title: 'Reminders on');
    }

    if (!unlocked) {
      return const _LockedRow(
        title: 'Turn on daily reminders',
        trailing: 'After step 1',
      );
    }

    return _ActiveCompactStep(
      index: 2,
      title: 'Turn on daily reminders',
      subtitle:
          'A nudge for the 9pm War and your daily practice — so you keep '
          'your streak and don’t drop off.',
      ctaLabel: 'Turn on reminders',
      onCta: () => unawaited(_enableReminders(ref)),
    );
  }
}

Future<void> _enableReminders(WidgetRef ref) async {
  await Analytics.track(
    ref,
    const ActivationJourneyTodoTappedEvent(todoIndex: 2),
  );
  final status = await BattleMessagingService.notificationAuthorizationStatus();
  if (BattleMessagingService.notificationAuthorizationAllowsPush(status)) {
    ref.invalidate(homeActivationJourneyProvider);
    return;
  }
  if (status == AuthorizationStatus.denied) {
    // Already-denied can't be re-prompted — deep-link to system Settings.
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  } else {
    await BattleMessagingService.requestPushAuthorizationIfNotDetermined(
      source: 'activation_reminders',
    );
  }
  ref.invalidate(homeActivationJourneyProvider);
}

class _ReminderLifecycleObserver with WidgetsBindingObserver {
  _ReminderLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

class _DangerZoneStep extends ConsumerWidget {
  const _DangerZoneStep({required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final done = state.todo3Done;
    final unlocked = state.todo3Unlocked;

    if (done) {
      return const _CollapsedDoneRow(title: 'Danger zone opened');
    }

    if (unlocked) {
      final preview = state.todo3IsPreview;
      return _ActiveCompactStep(
        index: 3,
        title: preview ? 'Peek at your danger zone' : 'See your danger zone',
        subtitle: preview
            ? 'An early read on where you’re confidently wrong. It '
                  'sharpens as you cross ${state.fullThreshold} attempts.'
            :
            'Topics where you\u2019re confidently wrong — and guesses that land right.',
        ctaLabel: preview ? 'Open early read' : 'Open map',
        showHelp: true,
        onHelp: () => unawaited(_showDangerZoneHelpSheet(context, state)),
        onCta: () => unawaited(_openDangerZone(context, ref, state)),
      );
    }

    final remaining = state.attemptsRemaining;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(_showDangerZoneHelpSheet(context, state)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'See your danger zone',
                            style: AppTextStyles.label().copyWith(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.help_outline_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${state.attemptsTowardNext}/${state.nextThreshold}',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: state.unlockProgress,
                        minHeight: 3,
                        backgroundColor:
                            scheme.onSurfaceVariant.withValues(alpha: 0.12),
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remaining == 0
                          ? 'Almost there — confident mistakes need volume to be real'
                          : '$remaining to go — confident mistakes need volume to be real',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        height: 1.3,
                      ),
                    ),
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

class _ActiveCompactStep extends StatelessWidget {
  const _ActiveCompactStep({
    required this.index,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.showHelp = false,
    this.onHelp,
  });

  final int index;
  final String title;
  final String subtitle;

  /// When null, the step renders without a button (passive / self-completing).
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool showHelp;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActiveBadge(index: index),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (showHelp && onHelp != null)
                      IconButton(
                        onPressed: onHelp,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: Icon(
                          Icons.help_outline_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (ctaLabel != null && onCta != null) ...[
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
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

class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.label().copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            trailing,
            style: AppTextStyles.caption().copyWith(color: muted),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
      width: 26,
      height: 26,
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
  final remaining = state.attemptsRemaining;
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Most aspirants know weak subjects. Few know where they feel '
                    'sure — and still get it wrong.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DangerZoneHelpBullet(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.wrong,
                    title: 'Confident & wrong',
                    body:
                        'Topics where you marked Sure / Educated guess but the '
                        'answer was incorrect — costly Prelims mistakes.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DangerZoneHelpBullet(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: AppColors.primary,
                    title: 'Guess & right',
                    body:
                        'Topics where your guesses land right more often — '
                        'signal you may know more than you think.',
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
                    child: Text(
                      unlocked
                          ? 'You\u2019ve logged enough attempts — open your map '
                              'to see these topics by subject.'
                          : 'We need about ${state.previewThreshold} attempted '
                              'questions with confidence marked for an early '
                              'read — the full map sharpens at '
                              '${state.fullThreshold}.\n\n'
                              'You\u2019re at ${state.scoredAttempts}'
                              '${remaining == 0 ? '.' : ' · $remaining to go.'} '
                              'Pick any subject below and keep practicing.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
