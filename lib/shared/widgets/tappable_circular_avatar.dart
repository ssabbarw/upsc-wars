import 'dart:ui';

import 'package:flutter/material.dart';

class TappableCircularAvatar extends StatelessWidget {
  const TappableCircularAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    required this.size,
    this.previewName,
  });

  final String? imageUrl;
  final String displayName;
  final double size;
  final String? previewName;

  @override
  Widget build(BuildContext context) {
    final url = _enhanceGooglePhotoUrl(imageUrl);
    final hasImage = url.trim().isNotEmpty;
    final monogram = _monogramFrom(displayName);
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onPrimaryContainer;
    final monogramFontSize = (size * 0.42).clamp(14.0, 42.0);

    return GestureDetector(
      onTap: hasImage ? () => _showFullscreenAvatar(context, url) : null,
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
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
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

String _enhanceGooglePhotoUrl(String? imageUrl) {
  final raw = imageUrl?.trim() ?? '';
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
