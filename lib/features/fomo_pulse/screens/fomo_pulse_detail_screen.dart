import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/fomo_pulse_share.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../widgets/fomo_pulse_hero_image.dart';

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
        ),
      ),
    );
  }
}

class _PulseBody extends HookConsumerWidget {
  const _PulseBody({
    required this.pulse,
    required this.attempt,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final alreadyAttempted = attempt?.attempted == true;

    final isHi = watchAppLanguage(ref) == 'hi';
    final summary = isHi && pulse.newsSummaryHi.trim().isNotEmpty
        ? pulse.newsSummaryHi
        : pulse.newsSummary;
    final points = isHi && pulse.upscPointsHi.isNotEmpty
        ? pulse.upscPointsHi
        : pulse.upscPoints;

    final stats = pulse.communityStats(
      minAttempts: FomoPulseConstants.minStatsAttempts,
    );

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
        if (stats != null && !alreadyAttempted) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            stats.challengeLine,
            style: AppTextStyles.label().copyWith(color: scheme.primary),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (pulse.isExpired && !alreadyAttempted)
          Text(
            'This Pulse has expired.',
            style: AppTextStyles.label().copyWith(color: scheme.error),
          )
        else ...[
          FilledButton(
            onPressed: () => context.push('/fomo-pulse/${pulse.pulseId}/mcq'),
            child: Text(
              alreadyAttempted ? 'Review your answer' : 'Attempt the MCQ',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            alreadyAttempted
                ? 'See your result and explanation'
                : '1 question · about 30 seconds',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _ShareAndSourceRow(
          pulse: pulse,
          stats: alreadyAttempted ? null : stats,
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

