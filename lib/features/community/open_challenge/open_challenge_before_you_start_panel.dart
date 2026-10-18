import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';

List<String> get _kOpenChallengeBeforeYouStartRuleLines => <String>[
  appL10n.ocRule1,
  appL10n.ocRule2,
  appL10n.ocRule3,
  appL10n.ocRule4,
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
          Text(context.l10n.ocBeforeStart, style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.sm),
          for (final line in _kOpenChallengeBeforeYouStartRuleLines)
            _openChallengeRuleBullet(line),
          Text(context.l10n.ocPleaseNote, style: AppTextStyles.label()),
          _openChallengeRuleBullet(context.l10n.ocConfidenceNote),
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
