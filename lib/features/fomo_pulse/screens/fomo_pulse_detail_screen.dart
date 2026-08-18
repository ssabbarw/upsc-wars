import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../widgets/fomo_pulse_question_block.dart';

class FomoPulseDetailScreen extends HookConsumerWidget {
  const FomoPulseDetailScreen({super.key, required this.pulseId});

  final String pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseDetailProvider(pulseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => _PulseBody(
          pulse: data.pulse,
          attempt: data.attempt,
          onSubmitted: () {
            ref.invalidate(fomoPulseDetailProvider(pulseId));
            ref.invalidate(fomoPulseHistoryProvider);
          },
        ),
      ),
    );
  }
}

class _PulseBody extends HookConsumerWidget {
  const _PulseBody({
    required this.pulse,
    required this.attempt,
    required this.onSubmitted,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? attempt;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final picked = useState<String?>(attempt?.selectedOption);
    final submitting = useState(false);
    final submitResult = useState<FomoPulseSubmitResult?>(null);
    final startedAt = useMemoized(() => DateTime.now());
    final alreadyAttempted = attempt?.attempted == true;

    final revealed = alreadyAttempted || submitResult.value != null;
    final isCorrect = submitResult.value?.isCorrect ?? attempt?.isCorrect ?? false;
    final stats = submitResult.value?.stats ?? pulse.communityStats(
          minAttempts: FomoPulseConstants.minStatsAttempts,
        );

    Future<void> submit(String option) async {
      if (submitting.value || revealed) return;
      picked.value = option;
      submitting.value = true;
      final secs = DateTime.now().difference(startedAt).inSeconds.clamp(1, 600);
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submit failed: $e')),
          );
        }
      } finally {
        submitting.value = false;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          pulse.title,
          style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
        ),
        if (pulse.body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            pulse.body,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (pulse.newsSummary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              pulse.newsSummary,
              style: AppTextStyles.bodySm().copyWith(height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (pulse.isExpired && !revealed)
          Text(
            'This Pulse has expired.',
            style: AppTextStyles.label().copyWith(color: scheme.error),
          )
        else
          FomoPulseQuestionBlock(
            question: pulse.question,
            picked: picked.value,
            onPick: revealed ? (_) {} : (o) => unawaited(submit(o)),
            busy: submitting.value,
            revealCorrect: revealed,
          ),
        if (revealed) ...[
          const SizedBox(height: AppSpacing.lg),
          _VerdictCard(
            isCorrect: isCorrect,
            selectedOption: picked.value ?? attempt?.selectedOption ?? '',
            correctOption: pulse.question.correctOption,
            question: pulse.question,
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                stats.line,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (pulse.question.finalExplanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Explanation', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              pulse.question.finalExplanation,
              style: AppTextStyles.bodySm().copyWith(height: 1.4),
            ),
          ],
        ],
        if (pulse.sourceUrl.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(pulse.sourceUrl);
              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Read source'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => context.go('/fomo-pulse'),
          child: const Text('All Pulses'),
        ),
      ],
    );
  }
}

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
            'Correct',
            Icons.check_circle_rounded,
          )
        : (
            isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
            isDark ? AppColors.wrongTextDark : AppColors.wrongText,
            'Incorrect',
            Icons.cancel_rounded,
          );

    return Container(
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
              Icon(icon, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.label().copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
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
