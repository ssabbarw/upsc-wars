import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class TappableCircularAvatar extends StatelessWidget {
  const TappableCircularAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    required this.size,
    this.previewName,
    this.enableImageTap = true,
  });

  final String? imageUrl;
  final String displayName;
  final double size;
  final String? previewName;
  /// When false, tapping the photo does not open fullscreen preview (parent can handle taps).
  final bool enableImageTap;

  @override
  Widget build(BuildContext context) {
    final url = _enhanceGooglePhotoUrl(
      AppConstants.customProfilePhotoUrl(imageUrl),
    );
    final hasImage = url.trim().isNotEmpty;
    final monogram = _monogramFrom(displayName);
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onPrimaryContainer;
    final monogramFontSize = (size * 0.42).clamp(14.0, 42.0);
    final cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return GestureDetector(
      onTap: enableImageTap && hasImage
          ? () => _showFullscreenAvatar(context, url)
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: size / 2,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                monogram,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontSize: monogramFontSize,
                ),
              ),
            ),
            if (hasImage)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  memCacheWidth: cachePx,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  errorWidget: (context, u, e) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFullscreenAvatar(BuildContext context, String image) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        final avatarSize = width * 0.72;
        final dialogCachePx =
            (avatarSize * MediaQuery.devicePixelRatioOf(dialogContext)).round();
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    memCacheWidth: dialogCachePx,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    errorWidget: (context, u, e) => Container(
                      width: avatarSize,
                      height: avatarSize,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade600,
                        size: avatarSize * 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if ((previewName ?? displayName).trim().isNotEmpty)
                  Text(
                    previewName ?? displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      dialogContext,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _enhanceGooglePhotoUrl(String imageUrl) {
  final raw = imageUrl.trim();
  if (raw.isEmpty) return '';
  return raw.replaceAll('s96-c', 's900-c');
}

String _monogramFrom(String? value) {
  final source = (value ?? '').trim();
  if (source.isEmpty) return 'U';
  final parts = source
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  return parts.first.substring(0, 1).toUpperCase();
}
