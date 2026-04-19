import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/test_session_provider.dart';

/// Optional confidence toggles under the selected option after the attempt is
/// scored (exam immediately, learning once the explanation is shown). Tap a tier
/// to set or switch; tap the active tier again to clear (stored as null).
///
/// Provide exactly one of [liveSessionId] (active test) or [reviewSessionId]
/// (session / results review persistence via repository).
class ExamOptionConfidenceStrip extends ConsumerWidget {
  const ExamOptionConfidenceStrip({
    super.key,
    required this.question,
    this.liveSessionId,
    this.reviewSessionId,
    this.onReviewConfidenceSaved,
    this.interactionLocked = false,
  }) : assert(
         (liveSessionId != null) != (reviewSessionId != null),
         'Provide exactly one of liveSessionId or reviewSessionId',
       );

  /// Active [testSessionProvider] session id.
  final String? liveSessionId;

  /// Persisted session id for [TestEngineRepository.updateAttemptConfidenceOnly].
  final String? reviewSessionId;

  /// Called after a successful review-mode write (e.g. invalidate providers).
  final VoidCallback? onReviewConfidenceSaved;

  /// Learning mode: after a tier is saved and the explanation is visible, taps
  /// are disabled so the first rating stays final for that attempt.
  final bool interactionLocked;

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
      if (interactionLocked) return;
      final next = question.confidence == tier ? null : tier;
      if (liveSessionId != null) {
        await ref
            .read(testSessionProvider(liveSessionId!).notifier)
            .updateExamQuestionConfidence(
              questionUuid: question.uuid,
              confidence: next,
            );
        return;
      }
      try {
        final repo = await ref.read(testEngineRepositoryProvider.future);
        await repo.updateAttemptConfidenceOnly(
          sessionId: reviewSessionId!,
          questionUuid: question.uuid,
          confidence: next,
        );
        onReviewConfidenceSaved?.call();
      } catch (_) {}
    }

    final confidenceLine = question.confidence == null
        ? 'Confidence: __'
        : 'Confidence: ${AnswerConfidence.examShortLabel(question.confidence!)}';

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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TierToggle(
                    label: 'Sure',
                    maxLines: 2,
                    selected: question.confidence == AnswerConfidence.verySure,
                    accent: AppColors.correct,
                    onSurface: AppColors.onPrimary,
                    labelUnselected: isDark
                        ? AppColors.correctTextDark
                        : AppColors.correctText,
                    isDark: isDark,
                    enabled: !interactionLocked,
                    onTap: () => toggle(AnswerConfidence.verySure),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TierToggle(
                    label: 'Intelligent\nguess',
                    maxLines: 2,
                    selected:
                        question.confidence == AnswerConfidence.somewhatSure,
                    accent: AppColors.warning,
                    onSurface: Colors.white,
                    labelUnselected: isDark
                        ? AppColors.warningTextDark
                        : AppColors.warningText,
                    isDark: isDark,
                    enabled: !interactionLocked,
                    onTap: () => toggle(AnswerConfidence.somewhatSure),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TierToggle(
                    label: 'Pure guess',
                    maxLines: 2,
                    selected: question.confidence == AnswerConfidence.guessing,
                    accent: AppColors.info,
                    onSurface: AppColors.onPrimary,
                    labelUnselected: isDark
                        ? AppColors.infoTextDark
                        : AppColors.infoText,
                    isDark: isDark,
                    enabled: !interactionLocked,
                    onTap: () => toggle(AnswerConfidence.guessing),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierToggle extends StatelessWidget {
  const _TierToggle({
    required this.label,
    required this.maxLines,
    required this.selected,
    required this.accent,
    required this.onSurface,
    required this.labelUnselected,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int maxLines;
  final bool selected;
  final Color accent;
  final Color onSurface;
  final Color labelUnselected;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? accent
        : accent.withValues(alpha: isDark ? 0.38 : 0.42);
    final border = Border.all(color: borderColor, width: selected ? 2.5 : 1);
    final inactiveDim = !enabled && !selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedOpacity(
          opacity: inactiveDim ? 0.42 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selected
                  ? accent
                  : accent.withValues(alpha: isDark ? 0.07 : 0.06),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: border,
              boxShadow: selected && enabled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: isDark ? 0.42 : 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : selected && !enabled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: isDark ? 0.22 : 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: onSurface,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm().copyWith(
                          color: selected ? onSurface : labelUnselected,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          height: 1.2,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
