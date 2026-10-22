import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/analytics.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/notifications/notification_prompt_policy.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/understand_home_dismiss_provider.dart';
import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/widgets/deferred_push_permission_sheet.dart';
import '../../l10n/l10n.dart';

final pushDeniedBannerVisibleProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  if (kIsWeb) return false;
  final prefs = await ref.watch(prefsServiceProvider.future);
  final session = ref.watch(understandHomeSessionHiddenProvider);
  // Legacy permanent flag + two-strike Understand dismiss.
  if (prefs.deferredPushHomeNudgeDismissedV2) return false;
  if (isUnderstandHomeHidden(
    prefs,
    session,
    UnderstandHomeDismissKeys.push,
  )) {
    return false;
  }
  return BattleMessagingService.shouldShowPushDeniedBanner();
});

/// Home / community nudge when OS push permission was denied.
///
/// [compact] is the one-line home strip. The default is the original card.
///
/// Emits [DeferredPushHomeNudgeShownEvent] / tap / dismissed for re-engagement
/// funnels. Set [reportShown] false on a duplicate instance so impressions
/// are not double-counted.
class PushDeniedBanner extends HookConsumerWidget {
  const PushDeniedBanner({
    super.key,
    this.compact = false,
    this.reportShown = true,
  });

  final bool compact;
  final bool reportShown;

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
      if (!visible || !reportShown) {
        if (!visible) loggedShown.value = false;
        return null;
      }
      if (loggedShown.value) return null;
      loggedShown.value = true;
      unawaited(Analytics.track(ref, const DeferredPushHomeNudgeShownEvent()));
      return null;
    }, [visible, reportShown]);

    if (!visible) return const SizedBox.shrink();

    return compact ? _CompactStrip(ref: ref) : _OriginalCard(ref: ref);
  }
}

class _CompactStrip extends StatelessWidget {
  const _CompactStrip({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = AppTextStyles.caption().copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.3,
    );
    final linkStyle = AppTextStyles.caption().copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w800,
      height: 1.3,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      TextSpan(text: context.l10n.pdLead),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () =>
                              unawaited(_promptThenOpenSettings(context, ref)),
                          child: Text(context.l10n.pdLink, style: linkStyle),
                        ),
                      ),
                      TextSpan(text: context.l10n.pdTrail),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => _dismiss(ref),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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

class _OriginalCard extends StatelessWidget {
  const _OriginalCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
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
                    context.l10n.pdTitle,
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.pdBody,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        unawaited(_promptThenOpenSettings(context, ref)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.pdEnable,
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
              tooltip: context.l10n.commonDismiss,
              visualDensity: VisualDensity.compact,
              onPressed: () => _dismiss(ref),
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

Future<void> _promptThenOpenSettings(
  BuildContext context,
  WidgetRef ref,
) async {
  unawaited(Analytics.track(ref, const DeferredPushHomeNudgeTapEnableEvent()));
  if (!context.mounted) return;
  final accepted = await showDeferredPushPermissionSheet(
    context,
    source: 'home_nudge',
    surface: NotificationPromptSurface.generic,
    kind: NotificationPromptKind.explicit,
  );
  if (accepted == true) {
    await BattleMessagingService.requestPushAuthorizationAndSync(
      source: 'home_nudge',
    );
    if (!await BattleMessagingService.notificationsAreEnabled()) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
  }
  ref.invalidate(pushDeniedBannerVisibleProvider);
}

void _dismiss(WidgetRef ref) {
  unawaited(Analytics.track(ref, const DeferredPushHomeNudgeDismissedEvent()));
  dismissUnderstandHomeItem(
    ref,
    UnderstandHomeDismissKeys.push,
    afterPersist: (prefs, newCount) {
      // Keep legacy flag in sync once permanently dismissed (second strike).
      if (newCount >= 2) {
        prefs.deferredPushHomeNudgeDismissedV2 = true;
      }
    },
  );
}

class _PushDeniedBannerLifecycleObserver with WidgetsBindingObserver {
  _PushDeniedBannerLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}
