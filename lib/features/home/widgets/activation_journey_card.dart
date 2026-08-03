import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/home_activation_journey_provider.dart';
import 'get_started_card.dart';

/// Three-step activation checklist shown on home until the confidence map opens.
class ActivationJourneyCard extends HookConsumerWidget {
  const ActivationJourneyCard({super.key, required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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
            todo2Unlocked: state.todo2Unlocked,
          ),
        ),
      );
      return null;
    }, const []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'YOUR FIRST STEPS',
          style: AppTextStyles.caption().copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!state.todo1Done)
          const _Todo1Expanded()
        else
          _ChecklistRow(
            index: 1,
            done: true,
            title: 'Demo test done',
            subtitle: 'You saw traps, analysis, and rich explanations.',
            onTap: null,
          ),
        const SizedBox(height: AppSpacing.sm),
        _Todo2Row(state: state),
        const SizedBox(height: AppSpacing.sm),
        _Todo3Row(state: state),
      ],
    );
  }
}

class _Todo1Expanded extends ConsumerWidget {
  const _Todo1Expanded();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.lg),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDeep.withValues(alpha: 0.18)
                    : AppColors.primaryLight.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.lg),
                ),
                border: Border(
                  top: BorderSide(color: borderColor.withValues(alpha: 0.4)),
                  right: BorderSide(color: borderColor.withValues(alpha: 0.4)),
                  bottom: BorderSide(color: borderColor.withValues(alpha: 0.4)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'STEP 1 · 5 MIN · 7 MCQs',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Try a demo test',
                    style: AppTextStyles.h3().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'See traps, statement analysis, and explanations that '
                    'actually teach — not just right or wrong.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        'Let\u2019s go',
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
        ],
      ),
    );
  }
}

class _Todo2Row extends ConsumerWidget {
  const _Todo2Row({required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = state.todo2Unlocked;
    final done = state.todo2Done;

    final subtitle = done
        ? 'Your confident-wrong and guess-right topics are ready.'
        : unlocked
            ? 'See where you\u2019re confidently wrong — and where guesses land right.'
            : '${state.attemptsTowardUnlock} / ${state.unlockThreshold} questions '
                'toward your confidence map';

    return _ChecklistRow(
      index: 2,
      done: done,
      locked: !unlocked && !done,
      title: done
          ? 'Confidence map unlocked'
          : unlocked
              ? 'Open your confidence map'
              : 'Unlock your confidence map',
      subtitle: subtitle,
      progress: unlocked || done ? null : state.unlockProgress,
      onTap: () {
        if (!unlocked) {
          unawaited(() async {
            await Analytics.track(
              ref,
              const ActivationJourneyTodoTappedEvent(todoIndex: 2),
            );
            if (context.mounted) await _showLockedSheet(context, state);
          }());
          return;
        }
        unawaited(_openConfidenceMap(context, ref, state));
      },
    );
  }
}

class _Todo3Row extends ConsumerWidget {
  const _Todo3Row({required this.state});

  final HomeActivationJourneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChecklistRow(
      index: 3,
      done: state.todo3Done,
      muted: true,
      title: state.todo3Done ? 'Games tried' : 'Try a fun revision game',
      subtitle: 'Memory, timelines, duels — lighter practice when you want it.',
      onTap: state.todo3Done
          ? null
          : () async {
              await Analytics.track(
                ref,
                const ActivationJourneyTodoTappedEvent(todoIndex: 3),
              );
              await markActivationGamesOpened(ref);
              if (context.mounted) context.go('/games');
            },
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.index,
    required this.done,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.locked = false,
    this.muted = false,
    this.progress,
  });

  final int index;
  final bool done;
  final bool locked;
  final bool muted;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final opacity = muted && !done ? 0.85 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepBadge(
                  index: index,
                  done: done,
                  locked: locked,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: scheme.onSurfaceVariant
                                .withValues(alpha: 0.12),
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.index,
    required this.done,
    required this.locked,
  });

  final int index;
  final bool done;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (done) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.correct,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }

    if (locked) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$index',
        style: AppTextStyles.caption().copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Future<void> _openConfidenceMap(
  BuildContext context,
  WidgetRef ref,
  HomeActivationJourneyState state,
) async {
  await Analytics.track(
    ref,
    const ActivationJourneyTodoTappedEvent(todoIndex: 2),
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

Future<void> _showLockedSheet(
  BuildContext context,
  HomeActivationJourneyState state,
) async {
  final remaining =
      (state.unlockThreshold - state.scoredAttempts).clamp(0, state.unlockThreshold);

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
                    'Your confidence map needs more signal',
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'After about ${state.unlockThreshold} attempted questions '
                    'with confidence marked, we can show topics where you\u2019re '
                    'confidently wrong — and where your guesses land right.\n\n'
                    'You\u2019re at ${state.scoredAttempts}. '
                    '${remaining == 0 ? 'Almost there.' : '$remaining more to go.'} '
                    'Pick any subject below and keep practicing.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
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

/// Slim Daily War placeholder while the activation journey mutes the hero.
class DailyWarMutedStrip extends StatelessWidget {
  const DailyWarMutedStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Daily War unlocks with your confidence map',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
