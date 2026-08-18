import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/fomo_pulse_share.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../widgets/fomo_pulse_question_block.dart';

/// Full-screen MCQ experience for a Fomo Pulse.
///
/// Flow:
///   1. Question + options shown.
///   2. User taps an option → confidence bottom sheet slides up.
///   3. User picks confidence → attempt submitted → verdict + explanation revealed.
class FomoPulseMcqScreen extends HookConsumerWidget {
  const FomoPulseMcqScreen({super.key, required this.pulseId});

  final String pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseDetailProvider(pulseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Attempt')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Could not load this Pulse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(fomoPulseDetailProvider(pulseId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _McqBody(
          pulse: data.pulse,
          existingAttempt: data.attempt,
          onSubmitted: () {
            ref.invalidate(fomoPulseDetailProvider(pulseId));
            ref.invalidate(fomoPulseHistoryProvider);
          },
        ),
      ),
    );
  }
}

class _McqBody extends HookConsumerWidget {
  const _McqBody({
    required this.pulse,
    required this.existingAttempt,
    required this.onSubmitted,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? existingAttempt;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHi = watchAppLanguage(ref) == 'hi';
    final question = pulse.question.localized(isHi);

    final alreadyAttempted = existingAttempt?.attempted == true;

    // If already attempted, skip straight to revealed state.
    final picked = useState<String?>(existingAttempt?.selectedOption);
    final confidence = useState<String?>(null);
    final submitting = useState(false);
    final submitResult = useState<FomoPulseSubmitResult?>(null);
    final startedAt = useState<DateTime?>(
      alreadyAttempted ? DateTime.now() : null,
    );

    final revealed = alreadyAttempted || submitResult.value != null;
    final isCorrect =
        submitResult.value?.isCorrect ?? existingAttempt?.isCorrect ?? false;
    final stats = submitResult.value?.stats ??
        pulse.communityStats(minAttempts: FomoPulseConstants.minStatsAttempts);

    Future<void> submit(String option, String conf) async {
      if (submitting.value || revealed) return;
      picked.value = option;
      confidence.value = conf;
      submitting.value = true;
      final start = startedAt.value ?? DateTime.now();
      final secs = DateTime.now().difference(start).inSeconds.clamp(1, 600);
      try {
        final cloud = ref.read(fomoPulseCloudServiceProvider);
        final result = await cloud.submitAttempt(
          pulseId: pulse.pulseId,
          selectedOption: option,
          timeSpentSecs: secs,
        );
        submitResult.value = result;
        await ref.read(fomoPulseRepositoryProvider).recordLocalAttempt(
              pulseId: pulse.pulseId,
              result: result,
            );
        if (!result.alreadyAttempted) {
          unawaited(AdminDashboardWriterService().recordFomoPulseEngagement());
        }
        onSubmitted();
      } catch (e) {
        picked.value = null;
        confidence.value = null;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submit failed: $e')),
          );
        }
      } finally {
        submitting.value = false;
      }
    }

    Future<void> onOptionTapped(String option) async {
      if (revealed || submitting.value) return;
      // Start the timer on first tap.
      startedAt.value ??= DateTime.now();

      // Show confidence sheet; wait for result.
      final conf = await showModalBottomSheet<String>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => _ConfidenceSheet(selectedOption: option),
      );
      if (conf == null || !context.mounted) return;
      await submit(option, conf);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        // ── Question ──────────────────────────────────────────────────────
        FomoPulseQuestionBlock(
          question: question,
          picked: picked.value,
          onPick: revealed ? (_) {} : (o) => unawaited(onOptionTapped(o)),
          busy: submitting.value,
          revealCorrect: revealed,
        ),

        // ── Already attempted banner ──────────────────────────────────────
        if (alreadyAttempted && submitResult.value == null) ...[
          const SizedBox(height: AppSpacing.lg),
          _AlreadyAttemptedBanner(isCorrect: existingAttempt!.isCorrect),
        ],

        // ── Verdict + explanation (after submit) ──────────────────────────
        if (revealed) ...[
          const SizedBox(height: AppSpacing.lg),
          _VerdictCard(
            isCorrect: isCorrect,
            selectedOption: picked.value ?? existingAttempt?.selectedOption ?? '',
            correctOption: question.correctOption,
            question: question,
            confidence: confidence.value,
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                stats.trapLine,
                style: AppTextStyles.caption().copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (question.finalExplanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Explanation', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                question.finalExplanation,
                style: AppTextStyles.bodySm().copyWith(height: 1.5),
              ),
            ),
          ],
          if (isCorrect) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: () => unawaited(
                shareFomoPulse(pulse, bragCorrect: true, stats: stats),
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text("I didn't fall for it — share"),
            ),
          ],
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confidence bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceSheet extends StatelessWidget {
  const _ConfidenceSheet({required this.selectedOption});

  final String selectedOption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How confident are you?',
              style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You picked option ${selectedOption.toUpperCase()}',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _ConfidenceButton(
              label: '✅  Sure — I know this',
              sublabel: 'Confident in my answer',
              accent: AppColors.correct,
              textColor: isDark ? AppColors.correctTextDark : AppColors.correctText,
              bgColor: isDark ? AppColors.correctBgDark : AppColors.correctBg,
              onTap: () => Navigator.of(context).pop('very_sure'),
            ),
            const SizedBox(height: AppSpacing.md),
            _ConfidenceButton(
              label: '🤔  Educated guess',
              sublabel: 'Mostly sure, not 100%',
              accent: AppColors.warning,
              textColor: isDark ? AppColors.warningTextDark : AppColors.warningText,
              bgColor: isDark ? AppColors.warningBgDark : AppColors.warningBg,
              onTap: () => Navigator.of(context).pop('somewhat_sure'),
            ),
            const SizedBox(height: AppSpacing.md),
            _ConfidenceButton(
              label: '🎲  Pure guess',
              sublabel: 'Just taking a shot',
              accent: AppColors.info,
              textColor: isDark ? AppColors.infoTextDark : AppColors.infoText,
              bgColor: isDark ? AppColors.infoBg : AppColors.infoBg,
              onTap: () => Navigator.of(context).pop('guessing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceButton extends StatelessWidget {
  const _ConfidenceButton({
    required this.label,
    required this.sublabel,
    required this.accent,
    required this.textColor,
    required this.bgColor,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Color accent;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body().copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: AppTextStyles.caption().copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verdict card
// ─────────────────────────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.isCorrect,
    required this.selectedOption,
    required this.correctOption,
    required this.question,
    this.confidence,
  });

  final bool isCorrect;
  final String selectedOption;
  final String correctOption;
  final FomoPulseQuestion question;
  final String? confidence;

  String _confidenceLabel(String c) => switch (c) {
        'very_sure' => 'Sure',
        'somewhat_sure' => 'Educated guess',
        'guessing' => 'Pure guess',
        _ => c,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, accent, label, icon) = isCorrect
        ? (
            isDark ? AppColors.correctBgDark : AppColors.correctBg,
            isDark ? AppColors.correctTextDark : AppColors.correctText,
            'Correct!',
            Icons.check_circle_rounded,
          )
        : (
            isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
            isDark ? AppColors.wrongTextDark : AppColors.wrongText,
            'Incorrect',
            Icons.cancel_rounded,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label().copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _confidenceLabel(confidence!),
                    style: AppTextStyles.caption().copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your answer: (${selectedOption.toUpperCase()}) '
            '${question.optionText(selectedOption)}',
            style: AppTextStyles.bodySm(),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Correct: (${correctOption.toUpperCase()}) '
              '${question.optionText(correctOption)}',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Already attempted banner
// ─────────────────────────────────────────────────────────────────────────────

class _AlreadyAttemptedBanner extends StatelessWidget {
  const _AlreadyAttemptedBanner({required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        isCorrect
            ? '✅ You got this right previously.'
            : '❌ You attempted this before — review below.',
        style: AppTextStyles.caption().copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

