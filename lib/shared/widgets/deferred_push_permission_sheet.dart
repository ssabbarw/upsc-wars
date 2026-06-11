import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/screen_flow_analytics.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/debug/upsc_wars_trace.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Returns `true` if the user chose to open the system permission flow.
Future<bool?> showDeferredPushPermissionSheet(
  BuildContext context, {
  required String source,
}) async {
  try {
    upscWarsTrace('showDeferredPushPermissionSheet: open source=$source');
    return await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      return _DeferredPushPermissionPanel(
        sheetContext: sheetContext,
        scheme: scheme,
        isDark: isDark,
        bottom: bottom,
        borderColor: borderColor,
        source: source,
      );
    },
    );
  } catch (e, st) {
    upscWarsTrace('showDeferredPushPermissionSheet', error: e, stackTrace: st);
    rethrow;
  }
}

class _NotificationBenefit {
  const _NotificationBenefit({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

const _notificationBenefits = [
  _NotificationBenefit(
    icon: Icons.newspaper_rounded,
    title: 'Current Affairs spot test',
    body:
        'One question from today\'s news — tap the notification and answer in seconds.',
  ),
  _NotificationBenefit(
    icon: Icons.sports_martial_arts_rounded,
    title: 'Battles & community',
    body:
        'Battle invites, open challenges, and updates when someone wants to play.',
  ),
  _NotificationBenefit(
    icon: Icons.live_tv_rounded,
    title: 'Online events',
    body:
        'Invites and reminders for live sessions, webinars, and group tests.',
  ),
  _NotificationBenefit(
    icon: Icons.local_fire_department_rounded,
    title: 'Daily practice nudges',
    body: 'A friendly tap so your prep streak doesn\'t quietly slip away.',
  ),
];

class _DeferredPushPermissionPanel extends HookConsumerWidget {
  const _DeferredPushPermissionPanel({
    required this.sheetContext,
    required this.scheme,
    required this.isDark,
    required this.bottom,
    required this.borderColor,
    required this.source,
  });

  final BuildContext sheetContext;
  final ColorScheme scheme;
  final bool isDark;
  final double bottom;
  final Color borderColor;
  final String source;

  Future<void> _closeWithOutcome(
    WidgetRef ref, {
    required bool tappedEnable,
  }) async {
    final prefs = await ref.read(prefsServiceProvider.future);
    final modalIndex = prefs.deferredPushModalShownCountV2 + 1;
    prefs.deferredPushModalShownCountV2 = modalIndex;
    if (tappedEnable) {
      prefs.deferredPushPermissionSheetCompletedV1 = true;
    }
    ref.invalidate(prefsServiceProvider);
    unawaited(
      ref.read(analyticsServiceProvider).track(
            DeferredPushEducationModalOutcomeEvent(
              source: source,
              modalIndex: modalIndex.clamp(1, 2),
              tappedEnableNotifications: tappedEnable,
            ),
          ),
    );
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop(tappedEnable);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final started = useRef(DateTime.now());
    final analytics = ref.read(analyticsServiceProvider);
    useEffect(
      () {
        unawaited(
          analytics.track(
            ScreenViewedEvent(screenName: ScreenFlow.deferredPushPrePrompt),
          ),
        );
        return () {
          final d =
              DateTime.now().difference(started.value).inMilliseconds;
          if (d < 0) return;
          unawaited(
            analytics.track(
              ScreenDwellEndedEvent(
                screenName: ScreenFlow.deferredPushPrePrompt,
                durationMs: d,
                endKind: 'modal_dismissed',
              ),
            ),
          );
        };
      },
      const [],
    );

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          bottom + AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border.all(color: borderColor.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withValues(
                  alpha: isDark ? 0.5 : 0.12,
                ),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Stay plugged into your prep',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3().copyWith(
                    color: scheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We only ping you when it actually helps. Here\'s what you\'ll get:',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ..._notificationBenefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(
                              alpha: isDark ? 0.35 : 0.55,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            benefit.icon,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                benefit.title,
                                style: AppTextStyles.body().copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                benefit.body,
                                style: AppTextStyles.bodySm().copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'You can turn these off anytime in Settings.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    upscWarsTrace('showDeferredPushPermissionSheet: tap_enable');
                    ScreenFlow.logAction(
                      ref,
                      screenName: ScreenFlow.deferredPushPrePrompt,
                      actionId: 'turn_on_notifications',
                    );
                    unawaited(_closeWithOutcome(ref, tappedEnable: true));
                  },
                  child: Text(
                    'Turn on alerts',
                    style: AppTextStyles.label(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    upscWarsTrace('showDeferredPushPermissionSheet: tap_not_now');
                    ScreenFlow.logAction(
                      ref,
                      screenName: ScreenFlow.deferredPushPrePrompt,
                      actionId: 'not_now',
                      actionKind: 'dismiss',
                    );
                    unawaited(_closeWithOutcome(ref, tappedEnable: false));
                  },
                  child: Text(
                    'Maybe later',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurfaceVariant,
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
