import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_source_links.dart';

class DailyCaSourceLinkRow extends StatelessWidget {
  const DailyCaSourceLinkRow({super.key, required this.link});

  final DailyCaSourceLink link;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final host = Uri.tryParse(link.url)?.host.replaceFirst('www.', '') ?? '';

    return Material(
      color: scheme.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => unawaited(_open(context, link.url)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: link.title,
                        style: AppTextStyles.caption().copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          height: 1.25,
                        ),
                      ),
                      if (host.isNotEmpty)
                        TextSpan(
                          text: '  $host',
                          style: AppTextStyles.caption().copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }
}
