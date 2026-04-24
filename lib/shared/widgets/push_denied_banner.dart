import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/services/battle_messaging_service.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

final pushDeniedBannerVisibleProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (kIsWeb) return false;
  final s = await BattleMessagingService.notificationAuthorizationStatus();
  return s == AuthorizationStatus.denied;
});

class PushDeniedBanner extends ConsumerWidget {
  const PushDeniedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pushDeniedBannerVisibleProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (visible) {
        if (!visible) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You’re missing Community alerts',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Turn on notifications to get battle invites, challenge updates, and chat replies.',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () async {
                    await AppSettings.openAppSettings(
                      type: AppSettingsType.notification,
                    );
                    ref.invalidate(pushDeniedBannerVisibleProvider);
                  },
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
        );
      },
    );
  }
}

