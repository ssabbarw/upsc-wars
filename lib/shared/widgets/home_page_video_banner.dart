import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/home_page_video_provider.dart';
import '../../core/providers/understand_home_dismiss_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../utils/youtube_thumb_cache.dart';
import '../utils/youtube_video_id.dart';
import '../../l10n/l10n.dart';

/// Remote Config [homePageVideoRemoteConfigKey]: message, Watch video, dismiss.
class HomePageVideoBanner extends ConsumerWidget {
  const HomePageVideoBanner({super.key, required this.borderColor});

  final Color borderColor;

  static void _dismiss(WidgetRef ref, int version) {
    final key = UnderstandHomeDismissKeys.video(version);
    dismissUnderstandHomeItem(
      ref,
      key,
      afterPersist: (prefs, newCount) {
        // Mirror permanent strike onto the legacy version flag.
        if (newCount >= 2) {
          prefs.homePageVideoDismissedVersion = version;
        }
      },
    );
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
            ? context.l10n.vbDefault
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
              child: Stack(
                children: [
                  _VideoPromoRow(
                    videoUrl: payload.videoUrl,
                    body: body,
                    onOpen: () => unawaited(_openVideo(payload.videoUrl)),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      tooltip: context.l10n.commonDismiss,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _dismiss(ref, payload.version),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
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

class _VideoPromoRow extends ConsumerWidget {
  const _VideoPromoRow({
    required this.videoUrl,
    required this.body,
    required this.onOpen,
  });

  final String videoUrl;
  final String body;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final thumbAsync = ref.watch(youtubeThumbMetaProvider(videoUrl));
    final meta = thumbAsync.asData?.value;
    final loading = thumbAsync.isLoading;
    final isPortrait = meta?.isPortrait ?? isYoutubeShortsUrl(videoUrl);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final thumbW = isPortrait
            ? (maxW * 0.22).clamp(64.0, 92.0)
            : (maxW * 0.34).clamp(104.0, 148.0);
        // Prefer decoded still aspect; fall back to 9:16 / 16:9 slots.
        final double aspect;
        if (meta != null && meta.height > meta.width) {
          aspect = meta.width / meta.height;
        } else if (isPortrait) {
          aspect = 9 / 16;
        } else if (meta != null && meta.width > 0 && meta.height > 0) {
          aspect = meta.width / meta.height;
        } else {
          aspect = 16 / 9;
        }
        final thumbH = thumbW / aspect;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: _VideoPromoThumbnail(
                width: thumbW,
                aspectRatio: aspect,
                videoUrl: videoUrl,
                meta: meta,
                loading: loading,
                onOpen: onOpen,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Container(
                width: 1,
                height: thumbH,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: AppTextStyles.body(),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onOpen,
                      icon: Icon(
                        Icons.play_circle_outline_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                      label: Text(
                        context.l10n.vbWatch,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoPromoThumbnail extends StatelessWidget {
  const _VideoPromoThumbnail({
    required this.width,
    required this.aspectRatio,
    required this.videoUrl,
    required this.meta,
    required this.loading,
    required this.onOpen,
  });

  final double width;
  final double aspectRatio;
  final String videoUrl;
  final YoutubeThumbMeta? meta;
  final bool loading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = meta?.videoId ?? extractYoutubeVideoId(videoUrl);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memW = (width * dpr).round().clamp(120, 800);
    final memH = (memW / aspectRatio).round().clamp(120, 1200);
    final playSize = (width * 0.28).clamp(20.0, 32.0);
    final scrim = AppColors.gray900;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (meta != null)
                  CachedNetworkImage(
                    cacheManager: youtubeThumbCacheManager,
                    imageUrl: meta!.imageUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 220),
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: memW,
                    memCacheHeight: memH,
                    placeholder: (_, _) => _ThumbLoading(
                      scheme: scheme,
                      isDark: isDark,
                    ),
                    errorWidget: (_, _, _) => _NonYoutubePlaceholder(
                      scheme: scheme,
                      isDark: isDark,
                    ),
                  )
                else if (loading)
                  _ThumbLoading(scheme: scheme, isDark: isDark)
                else
                  _NonYoutubePlaceholder(scheme: scheme, isDark: isDark),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scrim.withValues(alpha: 0.05),
                        scrim.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scrim.withValues(alpha: 0.35),
                      boxShadow: [
                        BoxShadow(
                          color: scrim.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.onPrimary,
                        size: playSize,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scrim.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            id != null
                                ? Icons.smart_display_rounded
                                : Icons.link_rounded,
                            size: 11,
                            color: AppColors.onPrimary.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            id != null ? 'YouTube' : 'Video',
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.onPrimary.withValues(
                                alpha: 0.95,
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
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
    );
  }
}

class _ThumbLoading extends StatelessWidget {
  const _ThumbLoading({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceTertiaryDark : AppColors.gray100,
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
  }
}

class _NonYoutubePlaceholder extends StatelessWidget {
  const _NonYoutubePlaceholder({required this.scheme, required this.isDark});

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
          size: 36,
          color: scheme.primary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
