import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../push/push_revision_game_launch_params.dart';
import '../shared/revision_game_analytics.dart';

/// Temporary home entry to test push → games hub → config sheet without FCM.
class PushRevisionGameDebugCard extends StatefulWidget {
  const PushRevisionGameDebugCard({super.key});

  @override
  State<PushRevisionGameDebugCard> createState() =>
      _PushRevisionGameDebugCardState();
}

class _PushRevisionGameDebugCardState extends State<PushRevisionGameDebugCard> {
  static const _options = [
    RevisionGameNames.timelineSorter,
    RevisionGameNames.oddOneOut,
    RevisionGameNames.factOrBluff,
    RevisionGameNames.connectTheDots,
    RevisionGameNames.duel,
    RevisionGameNames.memoryPairs,
  ];

  String _gameId = RevisionGameNames.timelineSorter;

  void _openHubConfig() {
    final params = PushRevisionGameLaunchParams(gameId: _gameId);
    final err = params.validationError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.go(params.hubLocation);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.infoBgDark.withValues(alpha: 0.35)
            : AppColors.infoBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? AppColors.infoTextDark : AppColors.infoText)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DEBUG · Revision game push',
            style: AppTextStyles.caption().copyWith(
              color: isDark ? AppColors.infoTextDark : AppColors.infoText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Simulates FCM tap → Games hub → config sheet.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _gameId,
            decoration: const InputDecoration(
              labelText: 'game',
              isDense: true,
            ),
            items: [
              for (final id in _options)
                DropdownMenuItem(value: id, child: Text(id)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _gameId = v);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _openHubConfig,
            child: const Text('Open hub + config'),
          ),
        ],
      ),
    );
  }
}
