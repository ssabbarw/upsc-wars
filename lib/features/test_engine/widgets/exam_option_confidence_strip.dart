import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/test_session_provider.dart';

/// Exam-only: optional confidence toggles. Tap a tier to set or switch; tap the
/// active tier again to clear (stored as null).
class ExamOptionConfidenceStrip extends ConsumerWidget {
  const ExamOptionConfidenceStrip({
    super.key,
    required this.sessionId,
    required this.question,
  });

  final String sessionId;
  final TestQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsServiceProvider).value;
    if (prefs == null || !prefs.confidenceTrackingEnabled) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> toggle(String tier) async {
      final next = question.confidence == tier ? null : tier;
      await ref
          .read(testSessionProvider(sessionId).notifier)
          .updateExamQuestionConfidence(
            questionUuid: question.uuid,
            confidence: next,
          );
    }

    final confidenceLine = question.confidence == null
        ? 'Confidence level not rated'
        : 'Confidence level: ${AnswerConfidence.examShortLabel(question.confidence!)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            confidenceLine,
            style: AppTextStyles.caption().copyWith(
              color: question.confidence == null
                  ? scheme.onSurfaceVariant
                  : scheme.primary,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TierToggle(
                  label: 'Sure',
                  selected: question.confidence == AnswerConfidence.verySure,
                  accent: AppColors.correct,
                  onSurface: AppColors.onPrimary,
                  labelUnselected: isDark
                      ? AppColors.correctTextDark
                      : AppColors.correctText,
                  isDark: isDark,
                  onTap: () => toggle(AnswerConfidence.verySure),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TierToggle(
                  label: 'Intelligent guess',
                  selected: question.confidence == AnswerConfidence.somewhatSure,
                  accent: AppColors.warning,
                  onSurface: Colors.white,
                  labelUnselected: isDark
                      ? AppColors.warningTextDark
                      : AppColors.warningText,
                  isDark: isDark,
                  onTap: () => toggle(AnswerConfidence.somewhatSure),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TierToggle(
                  label: 'Pure guess',
                  selected: question.confidence == AnswerConfidence.guessing,
                  accent: scheme.tertiary,
                  onSurface: scheme.onTertiary,
                  labelUnselected: scheme.onTertiaryContainer,
                  isDark: isDark,
                  onTap: () => toggle(AnswerConfidence.guessing),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierToggle extends StatelessWidget {
  const _TierToggle({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onSurface,
    required this.labelUnselected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color onSurface;
  final Color labelUnselected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: selected ? accent : accent.withValues(alpha: isDark ? 0.55 : 0.65),
      width: selected ? 2 : 1.2,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent
                : accent.withValues(alpha: isDark ? 0.14 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: border,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm().copyWith(
                color: selected ? onSurface : labelUnselected,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1.15,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
