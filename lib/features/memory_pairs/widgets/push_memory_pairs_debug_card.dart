import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../push/push_memory_pairs_launch_params.dart';

/// Admin entry to test push → welcome → game without FCM.
class PushMemoryPairsDebugCard extends StatefulWidget {
  const PushMemoryPairsDebugCard({super.key});

  @override
  State<PushMemoryPairsDebugCard> createState() => _PushMemoryPairsDebugCardState();
}

class _PushMemoryPairsDebugCardState extends State<PushMemoryPairsDebugCard> {
  final _setId = TextEditingController(text: 'national_parks');
  final _title = TextEditingController(
    text: 'National Parks challenge',
  );
  final _body = TextEditingController(
    text: 'Match famous parks to their states — 6 pairs, under a minute.',
  );

  @override
  void dispose() {
    _setId.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _openWelcome() {
    final params = PushMemoryPairsLaunchParams(
      setId: _setId.text.trim(),
      title: _title.text.trim(),
      body: _body.text.trim(),
    );
    final err = params.validationError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.push(params.welcomeLocation);
  }

  @override
  Widget build(BuildContext context) {
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
            'DEBUG · Memory Pairs push',
            style: AppTextStyles.caption().copyWith(
              color: isDark ? AppColors.infoTextDark : AppColors.infoText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Simulates FCM tap → welcome screen → Start game.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _setId,
            decoration: const InputDecoration(
              labelText: 'Set id',
              hintText: 'national_parks',
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Notification title',
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _body,
            decoration: const InputDecoration(
              labelText: 'Notification body',
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: _openWelcome,
            child: const Text('Simulate push open'),
          ),
        ],
      ),
    );
  }
}
