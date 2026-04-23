import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/analytics.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/services/deferred_push_permission_coordinator.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

final deferredPushHomeNudgeVisibleProvider = FutureProvider.autoDispose<bool>(
  (ref) => DeferredPushPermissionCoordinator.homeNudgeShouldShow(ref),
);

/// One-line hint after the two deferred push education modals were used.
class DeferredPushHomeNudgeBanner extends ConsumerWidget {
  const DeferredPushHomeNudgeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(deferredPushHomeNudgeVisibleProvider);
    return visible.when(
      data: (show) {
        if (!show) return const SizedBox.shrink();
        return const _DeferredPushHomeNudgeWithAnalytics();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Fires [DeferredPushHomeNudgeShownEvent] once per mount when the nudge is visible.
class _DeferredPushHomeNudgeWithAnalytics extends HookConsumerWidget {
  const _DeferredPushHomeNudgeWithAnalytics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shownLogged = useRef(false);
    useEffect(() {
      if (shownLogged.value) return null;
      shownLogged.value = true;
      unawaited(
        Analytics.track(ref, const DeferredPushHomeNudgeShownEvent()),
      );
      return null;
    }, const []);

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'You may be missing insight updates from UPSC Wars.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  unawaited(
                    Analytics.track(
                      ref,
                      const DeferredPushHomeNudgeTapEnableEvent(),
                    ),
                  );
                  final status =
                      await BattleMessagingService
                          .notificationAuthorizationStatus();
                  if (!context.mounted) return;
                  if (status == AuthorizationStatus.denied) {
                    await AppSettings.openAppSettings(
                      type: AppSettingsType.notification,
                    );
                  } else {
                    await BattleMessagingService
                        .requestPushAuthorizationAndSync();
                  }
                  if (!context.mounted) return;
                  ref.invalidate(prefsServiceProvider);
                  ref.invalidate(deferredPushHomeNudgeVisibleProvider);
                },
                child: Text(
                  'Turn on notifications',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss',
                onPressed: () async {
                  unawaited(
                    Analytics.track(
                      ref,
                      const DeferredPushHomeNudgeDismissedEvent(),
                    ),
                  );
                  final svc = await ref.read(prefsServiceProvider.future);
                  svc.deferredPushHomeNudgeDismissedV2 = true;
                  if (!context.mounted) return;
                  ref.invalidate(prefsServiceProvider);
                  ref.invalidate(deferredPushHomeNudgeVisibleProvider);
                },
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
