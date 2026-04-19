import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/home_page_video_provider.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Remote Config [homePageVideoRemoteConfigKey]: message, Watch video, dismiss.
class HomePageVideoBanner extends ConsumerWidget {
  const HomePageVideoBanner({super.key, required this.borderColor});

  final Color borderColor;

  static Future<void> _confirmAndDismiss(
    BuildContext context,
    WidgetRef ref,
    int version,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dismiss?', style: AppTextStyles.h3()),
        content: Text(
          'Are you sure? You will not be reminded of this again.',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.label()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes', style: AppTextStyles.label()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.homePageVideoDismissedVersion = version;
    ref.invalidate(homePageVideoVisibleProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final visible = ref.watch(homePageVideoVisibleProvider);

    return visible.when(
      loading: () => const SizedBox.shrink(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
      data: (payload) {
        if (payload == null) return const SizedBox.shrink();
        final body = payload.message.trim().isEmpty
            ? 'We posted a short video that may help.'
            : payload.message.trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body, style: AppTextStyles.body()),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(payload.videoUrl);
                          if (uri == null) return;
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          'Watch video',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => unawaited(
                          _confirmAndDismiss(context, ref, payload.version),
                        ),
                        child: Text(
                          'Dismiss',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
