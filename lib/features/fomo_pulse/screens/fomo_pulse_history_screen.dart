import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/fomo_pulse_models.dart';
import '../providers/fomo_pulse_providers.dart';

class FomoPulseHistoryScreen extends ConsumerWidget {
  const FomoPulseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseHistoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          if (data.pulses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No Pulses yet. Breaking CA briefings will show up here.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(fomoPulseRepositoryProvider).loadHistory(
                    forceRefresh: true,
                  );
              ref.invalidate(fomoPulseHistoryProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: data.pulses.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final pulse = data.pulses[index];
                final attempt = data.attempts[pulse.pulseId];
                return _PulseHistoryTile(
                  pulse: pulse,
                  attempt: attempt,
                  onTap: () => context.push('/fomo-pulse/${pulse.pulseId}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PulseHistoryTile extends StatelessWidget {
  const _PulseHistoryTile({
    required this.pulse,
    required this.attempt,
    required this.onTap,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? attempt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attempted = attempt?.attempted == true;
    final date = pulse.sentAt;
    final dateLabel = date != null
        ? DateFormat('d MMM · h:mm a').format(date.toLocal())
        : '';

    final (badgeBg, badgeFg, badgeLabel) = !attempted
        ? (
            scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant,
            'Not done',
          )
        : attempt!.isCorrect
        ? (
            isDark ? AppColors.correctBgDark : AppColors.correctBg,
            isDark ? AppColors.correctTextDark : AppColors.correctText,
            'Done · Correct',
          )
        : (
            isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
            isDark ? AppColors.wrongTextDark : AppColors.wrongText,
            'Done · Wrong',
          );

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      pulse.title,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.caption().copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (pulse.body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  pulse.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  dateLabel,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
