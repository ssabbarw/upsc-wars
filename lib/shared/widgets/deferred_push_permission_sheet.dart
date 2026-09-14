import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/screen_flow_analytics.dart';
import '../../core/layout/system_insets.dart';
import '../../core/notifications/notification_prompt_policy.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/debug/upsc_wars_trace.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'dismissible_modal_sheet.dart';

/// Returns `true` if the user chose to open the system permission flow.
Future<bool?> showDeferredPushPermissionSheet(
  BuildContext context, {
  required String source,
  NotificationPromptSurface surface = NotificationPromptSurface.generic,
  NotificationPromptKind kind = NotificationPromptKind.explicit,
}) async {
  try {
    upscWarsTrace(
      'showDeferredPushPermissionSheet: open source=$source surface=$surface',
    );
    return await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DeferredPushPermissionPanel(
          sheetContext: sheetContext,
          source: source,
          surface: surface,
          kind: kind,
        );
      },
    );
  } catch (e, st) {
    upscWarsTrace('showDeferredPushPermissionSheet', error: e, stackTrace: st);
    rethrow;
  }
}

class _DeferredPushPermissionPanel extends HookConsumerWidget {
  const _DeferredPushPermissionPanel({
    required this.sheetContext,
    required this.source,
    required this.surface,
    required this.kind,
  });

  final BuildContext sheetContext;
  final String source;
  final NotificationPromptSurface surface;
  final NotificationPromptKind kind;

  Future<void> _recordOutcome(
    WidgetRef ref, {
    required bool tappedEnable,
  }) async {
    final prefs = await ref.read(prefsServiceProvider.future);
    if (kind == NotificationPromptKind.automatic) {
      prefs.deferredPushModalShownCountV2 =
          prefs.deferredPushModalShownCountV2 + 1;
      prefs.deferredPushLastAutomaticShownAt = DateTime.now();
    }
    if (tappedEnable) {
      prefs.deferredPushPermissionSheetCompletedV1 = true;
    }
    ref.invalidate(prefsServiceProvider);
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            DeferredPushEducationModalOutcomeEvent(
              source: source,
              modalIndex: prefs.deferredPushModalShownCountV2.clamp(1, 2),
              tappedEnableNotifications: tappedEnable,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final copy = NotificationPromptCopy.forSurface(surface);
    final started = useRef(DateTime.now());
    final recorded = useRef(false);
    final analytics = ref.read(analyticsServiceProvider);

    useEffect(() {
      unawaited(
        analytics.track(
          ScreenViewedEvent(screenName: ScreenFlow.deferredPushPrePrompt),
        ),
      );
      unawaited(
        analytics.track(DeferredPushEducationModalShownEvent(source: source)),
      );
      return () {
        final d = DateTime.now().difference(started.value).inMilliseconds;
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
    }, const []);

    Future<void> finish({required bool tappedEnable}) async {
      if (recorded.value) return;
      recorded.value = true;
      await _recordOutcome(ref, tappedEnable: tappedEnable);
    }

    Future<void> close({required bool tappedEnable}) async {
      await finish(tappedEnable: tappedEnable);
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop(tappedEnable);
      }
    }

    final sheetFill = isDark ? scheme.surface : AppColors.gray50;
    final iconWell = isDark
        ? AppColors.primaryDeep.withValues(alpha: 0.55)
        : AppColors.primaryLight;

    return DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          sheetBottomPadding(context),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: sheetFill,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: PopScope(
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) return;
                unawaited(finish(tappedEnable: result == true));
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconWell,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            copy.bullets.isNotEmpty
                                ? Icons.auto_awesome_rounded
                                : Icons.notifications_rounded,
                            size: 22,
                            color: isDark
                                ? AppColors.correctTextDark
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          copy.title,
                          style: AppTextStyles.h1().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          copy.body,
                          style: AppTextStyles.body().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        if (copy.bullets.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          for (final item in copy.bullets)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: AppTextStyles.bodySm().copyWith(
                                        color: scheme.onSurface,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          copy.alsoLine,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(
                          height: copy.bullets.isNotEmpty
                              ? AppSpacing.xl
                              : AppSpacing.xxl,
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              upscWarsTrace(
                                'showDeferredPushPermissionSheet: tap_enable',
                              );
                              ScreenFlow.logAction(
                                ref,
                                screenName: ScreenFlow.deferredPushPrePrompt,
                                actionId: 'turn_on_notifications',
                              );
                              unawaited(close(tappedEnable: true));
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            child: Text(
                              copy.cta,
                              style: AppTextStyles.label().copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              upscWarsTrace(
                                'showDeferredPushPermissionSheet: tap_not_now',
                              );
                              ScreenFlow.logAction(
                                ref,
                                screenName: ScreenFlow.deferredPushPrePrompt,
                                actionId: 'not_now',
                                actionKind: 'dismiss',
                              );
                              unawaited(close(tappedEnable: false));
                            },
                            child: Text(
                              NotificationPromptCopy.notNow,
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Center(
                          child: Text(
                            NotificationPromptCopy.footer,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
