import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';

List<String> get _kQotdBeforeYouProceedRuleLines => <String>[
  appL10n.qotdRule1,
  appL10n.qotdRule2,
  appL10n.qotdRule3,
  appL10n.qotdRule4,
  appL10n.qotdRule5,
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
          Text(context.l10n.qotdBeforeProceed, style: AppTextStyles.label()),
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
