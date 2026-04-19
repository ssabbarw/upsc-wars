import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/home_page_video_provider.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../utils/youtube_video_id.dart';

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

  static Future<void> _openVideo(String videoUrl) async {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            Material(
              color: scheme.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VideoPromoThumbnail(
                    videoUrl: payload.videoUrl,
                    onOpen: () => unawaited(_openVideo(payload.videoUrl)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Text(body, style: AppTextStyles.body()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => unawaited(_openVideo(payload.videoUrl)),
                          icon: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 20,
                            color: scheme.primary,
                          ),
                          label: Text(
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

class _VideoPromoThumbnail extends StatelessWidget {
  const _VideoPromoThumbnail({
    required this.videoUrl,
    required this.onOpen,
  });

  final String videoUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = extractYoutubeVideoId(videoUrl);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalW = MediaQuery.sizeOf(context).width;
    const thumbWidthFactor = 0.62;
    final thumbLogicalW = logicalW * thumbWidthFactor;
    final memW = (thumbLogicalW * dpr).round().clamp(240, 1200);
    final memH = (memW * 9 / 16).round();

    return Material(
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: thumbWidthFactor,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
              if (id != null)
                _CachedYoutubeStill(
                  videoId: id,
                  memCacheWidth: memW,
                  memCacheHeight: memH,
                  scheme: scheme,
                  isDark: isDark,
                )
              else
                _NonYoutubePlaceholder(scheme: scheme, isDark: isDark),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          id != null ? Icons.smart_display_rounded : Icons.link_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          id != null ? 'YouTube' : 'Video',
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
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
    );
  }
}

class _CachedYoutubeStill extends StatelessWidget {
  const _CachedYoutubeStill({
    required this.videoId,
    required this.memCacheWidth,
    required this.memCacheHeight,
    required this.scheme,
    required this.isDark,
  });

  final String videoId;
  final int memCacheWidth;
  final int memCacheHeight;
  final ColorScheme scheme;
  final bool isDark;

  String _thumbUrl(String quality) =>
      'https://i.ytimg.com/vi/$videoId/$quality.jpg';

  @override
  Widget build(BuildContext context) {
    final fallbackBg = isDark ? AppColors.surfaceTertiaryDark : AppColors.gray100;

    Widget placeholder() => ColoredBox(
          color: fallbackBg,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        );

    Widget iconFallback() => ColoredBox(
          color: fallbackBg,
          child: Center(
            child: Icon(
              Icons.smart_display_rounded,
              size: 56,
              color: scheme.primary.withValues(alpha: 0.35),
            ),
          ),
        );

    return CachedNetworkImage(
      imageUrl: _thumbUrl('maxresdefault'),
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: Duration.zero,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (_, _) => placeholder(),
      errorWidget: (_, _, _) => CachedNetworkImage(
        imageUrl: _thumbUrl('hqdefault'),
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 220),
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (_, _) => placeholder(),
        errorWidget: (_, _, _) => iconFallback(),
      ),
    );
  }
}

class _NonYoutubePlaceholder extends StatelessWidget {
  const _NonYoutubePlaceholder({
    required this.scheme,
    required this.isDark,
  });

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final a = scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14);
    final b = scheme.tertiary.withValues(alpha: isDark ? 0.12 : 0.10);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(scheme.surfaceContainerHighest, a, 0.85)!,
            Color.lerp(scheme.surfaceContainerHighest, b, 0.9)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.ondemand_video_rounded,
          size: 56,
          color: scheme.primary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
