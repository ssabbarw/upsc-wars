import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/domain/entities/test_question.dart';
import '../../core/providers/super_user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Shows the keyed correct answer and question UUID for verifying DB / stats.
/// Visible in [kDebugMode] and to signed-in super users (admins).
class DebugCorrectAnswerBanner extends ConsumerWidget {
  const DebugCorrectAnswerBanner({super.key, required this.question});

  final TestQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isSuperUserProvider);
    if (!kDebugMode && !isAdmin) return const SizedBox.shrink();
    final letter = question.correctOption.trim().toUpperCase();
    final label = kDebugMode ? 'Debug' : 'Admin';
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
              '$label — correct option: $letter',
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
