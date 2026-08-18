import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class FomoPulseHeroImage extends StatelessWidget {
  const FomoPulseHeroImage({
    super.key,
    required this.imageUrl,
    this.imageSource = '',
    this.height = 180,
  });

  final String imageUrl;
  final String imageSource;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: CachedNetworkImage(
            imageUrl: url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: height,
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        ),
        if (imageSource.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Photo: ${imageSource.trim()}',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
