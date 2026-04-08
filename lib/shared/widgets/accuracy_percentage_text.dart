import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/domain/entities/accuracy_display_tier.dart';
import '../../core/theme/app_text_styles.dart';
import '../extensions/accuracy_tier_colors.dart';

class AccuracyPercentageText extends HookConsumerWidget {
  const AccuracyPercentageText({
    super.key,
    required this.attemptCount,
    required this.accuracyPercent,
    required this.tier,
  });

  final int attemptCount;
  final double? accuracyPercent;
  final AccuracyDisplayTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label =
        attemptCount == 0 ? '—' : '${accuracyPercent!.round()}%';
    return Text(
      label,
      style: AppTextStyles.labelSm().copyWith(
        color: tier.resolveAccuracyForeground(context),
      ),
    );
  }
}
