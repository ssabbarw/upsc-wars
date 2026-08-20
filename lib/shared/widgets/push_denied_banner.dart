import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/analytics.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

final pushDeniedBannerVisibleProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  if (kIsWeb) return false;
  final prefs = await ref.watch(prefsServiceProvider.future);
  if (prefs.deferredPushHomeNudgeDismissedV2) return false;
  return BattleMessagingService.shouldShowPushDeniedBanner();
});

/// Home / community nudge when OS push permission was denied.
///
/// Emits [DeferredPushHomeNudgeShownEvent] / tap / dismissed for re-engagement
/// funnels.
class PushDeniedBanner extends HookConsumerWidget {
  const PushDeniedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      void refresh() => ref.invalidate(pushDeniedBannerVisibleProvider);
      BattleMessagingService.addNotificationPermissionChangeListener(refresh);
      final observer = _PushDeniedBannerLifecycleObserver(onResumed: refresh);
      WidgetsBinding.instance.addObserver(observer);
      return () {
        BattleMessagingService.removeNotificationPermissionChangeListener(
          refresh,
        );
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, const []);

    final async = ref.watch(pushDeniedBannerVisibleProvider);
    final visible = async.maybeWhen(data: (v) => v, orElse: () => false);
    final loggedShown = useRef(false);

    useEffect(() {
      if (!visible) {
        loggedShown.value = false;
        return null;
      }
      if (loggedShown.value) return null;
      loggedShown.value = true;
      unawaited(
        Analytics.track(ref, const DeferredPushHomeNudgeShownEvent()),
      );
      return null;
    }, [visible]);

    if (!visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You’re missing Static War, CA & community alerts',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Turn on notifications for tonight’s war, daily current affairs, practice reminders, and battle invites.',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () async {
                      unawaited(
                        Analytics.track(
                          ref,
                          const DeferredPushHomeNudgeTapEnableEvent(),
                        ),
                      );
                      await AppSettings.openAppSettings(
                        type: AppSettingsType.notification,
                      );
                      ref.invalidate(pushDeniedBannerVisibleProvider);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Enable alerts',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                unawaited(
                  Analytics.track(
                    ref,
                    const DeferredPushHomeNudgeDismissedEvent(),
                  ),
                );
                final prefs = await ref.read(prefsServiceProvider.future);
                prefs.deferredPushHomeNudgeDismissedV2 = true;
                ref.invalidate(prefsServiceProvider);
                ref.invalidate(pushDeniedBannerVisibleProvider);
              },
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushDeniedBannerLifecycleObserver with WidgetsBindingObserver {
  _PushDeniedBannerLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}
