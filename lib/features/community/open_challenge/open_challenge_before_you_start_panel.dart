import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

const _kOpenChallengeBeforeYouStartRuleLines = <String>[
  'You will answer 10 questions in exam mode — no hints, no explanations.',
  'Your score is posted publicly with your name.',
  'You can only attempt each challenge once.',
  'Ties are broken by who attempted earlier.',
];

/// Shown on pick-subject so expectations are visible before starting the exam.
class OpenChallengeBeforeYouStartPanel extends StatelessWidget {
  const OpenChallengeBeforeYouStartPanel({super.key, required this.scheme});

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
          Text('Before you start', style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.sm),
          for (final line in _kOpenChallengeBeforeYouStartRuleLines)
            _openChallengeRuleBullet(line),
          Text("Please note:", style: AppTextStyles.label()),
          _openChallengeRuleBullet(
            'While selecting an option, marking confidence level is optional, but we recommend it for better insights.',
          ),
        ],
      ),
    );
  }
}

Widget _openChallengeRuleBullet(String text) {
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
