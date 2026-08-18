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
/// The pulse carries its own answer key and explanation, so tapping an option
/// reveals the verdict straight away and the attempt is reported in the
/// background.
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

    // Captured once: refreshing after a submit flips [existingAttempt] to
    // attempted, which must not turn a fresh verdict into a review banner.
    final attemptedOnOpen = useRef(existingAttempt?.attempted == true).value;
    final openedAt = useMemoized(DateTime.now);

    final picked = useState<String?>(existingAttempt?.selectedOption);
    final serverStats = useState<FomoPulseCommunityStats?>(null);

    final revealed = attemptedOnOpen || picked.value != null;
    final selected = picked.value ?? '';
    final isCorrect = selected.isEmpty
        ? existingAttempt?.isCorrect ?? false
        : selected.toLowerCase() == question.correctOption.toLowerCase();
    final stats =
        serverStats.value ??
        pulse.communityStats(minAttempts: FomoPulseConstants.minStatsAttempts);

    /// Reports the attempt after the verdict is already on screen. Only the
    /// community counters depend on the response, so a failure is silent.
    Future<void> report(String option, bool wasCorrect) async {
      final secs = DateTime.now().difference(openedAt).inSeconds.clamp(1, 600);
      // Resolved up front: [ref] is unusable once this screen is popped.
      final repo = ref.read(fomoPulseRepositoryProvider);
      final cloud = ref.read(fomoPulseCloudServiceProvider);
      final local = FomoPulseSubmitResult(
        isCorrect: wasCorrect,
        selectedOption: option,
        correctOption: question.correctOption,
        alreadyAttempted: false,
        timeSpentSecs: secs,
      );
      // Persist first so the attempt survives with no connectivity.
      await repo.recordLocalAttempt(
        pulseId: pulse.pulseId,
        result: local,
        updateCommunityCounts: false,
      );
      try {
        final result = await cloud.submitAttempt(
          pulseId: pulse.pulseId,
          selectedOption: option,
          timeSpentSecs: secs,
        );
        await repo.recordLocalAttempt(pulseId: pulse.pulseId, result: result);
        if (!result.alreadyAttempted) {
          unawaited(AdminDashboardWriterService().recordFomoPulseEngagement());
        }
        if (!context.mounted) return;
        if (result.stats != null) serverStats.value = result.stats;
        onSubmitted();
      } catch (_) {
        // Verdict came from local data; community stats stay as cached.
      }
    }

    void onOptionTapped(String option) {
      // `picked.value` rather than `revealed` so a second tap arriving before
      // the rebuild is still rejected.
      if (revealed || picked.value != null) return;
      // Grading only needs the pulse we already hold, so reveal immediately.
      picked.value = option;
      unawaited(
        report(
          option,
          option.toLowerCase() == question.correctOption.toLowerCase(),
        ),
      );
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
          onPick: revealed ? (_) {} : onOptionTapped,
          revealCorrect: revealed,
        ),

        // ── Already attempted banner ──────────────────────────────────────
        if (attemptedOnOpen) ...[
          const SizedBox(height: AppSpacing.lg),
          _AlreadyAttemptedBanner(isCorrect: isCorrect),
        ],

        // ── Verdict + explanation ─────────────────────────────────────────
        if (revealed) ...[
          const SizedBox(height: AppSpacing.lg),
          _VerdictCard(
            isCorrect: isCorrect,
            selectedOption: selected,
            correctOption: question.correctOption,
            question: question,
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
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
// Verdict card
// ─────────────────────────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.isCorrect,
    required this.selectedOption,
    required this.correctOption,
    required this.question,
  });

  final bool isCorrect;
  final String selectedOption;
  final String correctOption;
  final FomoPulseQuestion question;

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
            ],
          ),
          if (selectedOption.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your answer: (${selectedOption.toUpperCase()}) '
              '${question.optionText(selectedOption)}',
              style: AppTextStyles.bodySm(),
            ),
          ],
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
        style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
