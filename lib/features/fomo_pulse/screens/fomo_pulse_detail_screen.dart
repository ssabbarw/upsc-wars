import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/fomo_pulse_hero_image.dart';
import '../widgets/fomo_pulse_question_block.dart';

class FomoPulseDetailScreen extends HookConsumerWidget {
  const FomoPulseDetailScreen({super.key, required this.pulseId});

  final String pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseDetailProvider(pulseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse'),
        actions: [
          async.maybeWhen(
            data: (data) => IconButton(
              tooltip: 'Share',
              onPressed: () => unawaited(
                shareFomoPulse(
                  data.pulse,
                  stats: data.pulse.communityStats(
                    minAttempts: FomoPulseConstants.minStatsAttempts,
                  ),
                ),
              ),
              icon: const Icon(Icons.share_outlined),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not load this Pulse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
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
    final showMcq = useState(attempt?.attempted == true);
    final mcqStartedAt = useState<DateTime?>(null);
    final alreadyAttempted = attempt?.attempted == true;

    final isHi = watchAppLanguage(ref) == 'hi';
    final question = pulse.question.localized(isHi);
    final summary = isHi && pulse.newsSummaryHi.trim().isNotEmpty
        ? pulse.newsSummaryHi
        : pulse.newsSummary;
    final points = isHi && pulse.upscPointsHi.isNotEmpty
        ? pulse.upscPointsHi
        : pulse.upscPoints;

    final revealed = alreadyAttempted || submitResult.value != null;
    final isCorrect =
        submitResult.value?.isCorrect ?? attempt?.isCorrect ?? false;
    final stats = submitResult.value?.stats ??
        pulse.communityStats(minAttempts: FomoPulseConstants.minStatsAttempts);

    Future<void> submit(String option) async {
      if (submitting.value || revealed) return;
      picked.value = option;
      submitting.value = true;
      final start = mcqStartedAt.value ?? DateTime.now();
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
        FomoPulseHeroImage(
          imageUrl: pulse.imageUrl,
          imageSource: pulse.imageSource,
        ),
        if (pulse.imageUrl.trim().isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        Text(
          pulse.title,
          style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            summary,
            style: AppTextStyles.body().copyWith(height: 1.4),
          ),
        ] else if (pulse.body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            pulse.body,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
        if (points.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('For UPSC', style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.xs),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('• $p', style: AppTextStyles.bodySm()),
            ),
          ),
        ],
        if (stats != null && !revealed) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            stats.challengeLine,
            style: AppTextStyles.label().copyWith(color: scheme.primary),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (pulse.isExpired && !revealed)
          Text(
            'This Pulse has expired.',
            style: AppTextStyles.label().copyWith(color: scheme.error),
          )
        else if (!showMcq.value) ...[
          FilledButton(
            onPressed: () {
              showMcq.value = true;
              mcqStartedAt.value = DateTime.now();
            },
            child: const Text('Attempt the MCQ'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1 question · about 30 seconds',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          FomoPulseQuestionBlock(
            question: question,
            picked: picked.value,
            onPick: revealed ? (_) {} : (o) => unawaited(submit(o)),
            busy: submitting.value,
            revealCorrect: revealed,
          ),
        ],
        if (revealed) ...[
          const SizedBox(height: AppSpacing.lg),
          _VerdictCard(
            isCorrect: isCorrect,
            selectedOption: picked.value ?? attempt?.selectedOption ?? '',
            correctOption: question.correctOption,
            question: question,
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                stats.trapLine,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (question.finalExplanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Explanation', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              question.finalExplanation,
              style: AppTextStyles.bodySm().copyWith(height: 1.4),
            ),
          ],
          if (isCorrect) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: () => unawaited(
                shareFomoPulse(
                  pulse,
                  bragCorrect: true,
                  stats: stats,
                ),
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text("I didn't fall for it — share"),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        _ShareAndSourceRow(
          pulse: pulse,
          stats: revealed ? null : stats,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => context.go('/fomo-pulse'),
          child: const Text('All Pulses'),
        ),
      ],
    );
  }
}

class _ShareAndSourceRow extends StatelessWidget {
  const _ShareAndSourceRow({
    required this.pulse,
    this.stats,
  });

  final FomoPulse pulse;
  final FomoPulseCommunityStats? stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => unawaited(
              shareFomoPulse(pulse, stats: stats),
            ),
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share'),
          ),
        ),
        if (pulse.sourceUrl.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(pulse.sourceUrl);
                if (uri != null) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Read source'),
            ),
          ),
        ],
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
