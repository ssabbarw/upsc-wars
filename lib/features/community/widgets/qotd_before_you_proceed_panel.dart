import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

const _kQotdBeforeYouProceedRuleLines = <String>[
  'Each QOTD stays in Community for 24 hours from when you post it.',
  'One random MCQ is drawn from your offline catalog for the subject you pick.',
  'Shuffle until you find a question worth sharing, then attempt it.',
  'You post after attempting; your pick is stored with the community post.',
  'Your name and an optional short comment appear on the QOTD card.',
];

/// Shown on the post-QOTD subject step so expectations are clear before continuing.
class QotdBeforeYouProceedPanel extends StatelessWidget {
  const QotdBeforeYouProceedPanel({super.key, required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before you proceed', style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.sm),
          for (final line in _kQotdBeforeYouProceedRuleLines)
            _qotdRuleBullet(line),
        ],
      ),
    );
  }
}

Widget _qotdRuleBullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• '),
        Expanded(child: Text(text, style: AppTextStyles.bodySm())),
      ],
    ),
  );
}
