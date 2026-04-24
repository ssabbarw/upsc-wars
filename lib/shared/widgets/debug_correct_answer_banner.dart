import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/domain/entities/test_question.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// In [kDebugMode] only: shows the keyed correct answer and question UUID for verifying DB / stats.
class DebugCorrectAnswerBanner extends StatelessWidget {
  const DebugCorrectAnswerBanner({super.key, required this.question});

  final TestQuestion question;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return const SizedBox.shrink();
    final letter = question.correctOption.trim().toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.warning, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug — correct option: $letter',
              style: AppTextStyles.labelSm().copyWith(
                color: AppColors.warningText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              question.uuid,
              style: AppTextStyles.caption().copyWith(
                color: AppColors.warningText,
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
