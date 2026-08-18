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
      appBar: AppBar(
        title: const Text('CA Shots'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showWhatIsCaShotsSheet(context),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text("What's this?"),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          if (data.pulses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No CA Shots yet. Breaking CA briefings will show up here.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          final sections = _groupByDate(data.pulses);
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(fomoPulseRepositoryProvider)
                  .loadHistory(forceRefresh: true);
              ref.invalidate(fomoPulseHistoryProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = sections[sectionIndex];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: sectionIndex == sections.length - 1
                        ? 0
                        : AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.label,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (var i = 0; i < section.pulses.length; i++) ...[
                        _PulseHistoryTile(
                          pulse: section.pulses[i],
                          attempt: data.attempts[section.pulses[i].pulseId],
                          onTap: () => context.push(
                            '/fomo-pulse/${section.pulses[i].pulseId}',
                          ),
                        ),
                        if (i != section.pulses.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void _showWhatIsCaShotsSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are CA Shots?',
                style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Think of these as short daily drills — shots you can take every day to prepare for your final battle.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExplainerRow(
                icon: Icons.notifications_active_outlined,
                title: 'Frequent alerts',
                body:
                    'You get notified when a UPSC-relevant article is worth your attention.',
              ),
              const SizedBox(height: AppSpacing.md),
              _ExplainerRow(
                icon: Icons.quiz_outlined,
                title: 'One focused MCQ',
                body:
                    'Each shot gives one concept-based MCQ from that article, with explanation.',
              ),
              const SizedBox(height: AppSpacing.md),
              _ExplainerRow(
                icon: Icons.shield_outlined,
                title: 'Battle readiness',
                body:
                    'Take these shots daily so your concepts stay sharp for the final battle.',
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ExplainerRow extends StatelessWidget {
  const _ExplainerRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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
        ? (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, 'Not done')
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
                  _PulseThumbnail(pulse: pulse),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      pulse.title,
                      style: AppTextStyles.label().copyWith(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseThumbnail extends StatelessWidget {
  const _PulseThumbnail({required this.pulse});

  final FomoPulse pulse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = pulse.imageUrl.trim();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: scheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _HistorySection {
  const _HistorySection({required this.label, required this.pulses});

  final String label;
  final List<FomoPulse> pulses;
}

List<_HistorySection> _groupByDate(List<FomoPulse> pulses) {
  final groups = <String, List<FomoPulse>>{};
  for (final p in pulses) {
    final local = p.sentAt?.toLocal();
    final key = local == null
        ? 'undated'
        : DateFormat('yyyy-MM-dd').format(local);
    groups.putIfAbsent(key, () => []).add(p);
  }
  final keys = groups.keys.toList()
    ..sort((a, b) {
      if (a == 'undated') return 1;
      if (b == 'undated') return -1;
      return b.compareTo(a);
    });
  return [
    for (final key in keys)
      _HistorySection(
        label: key == 'undated'
            ? 'Undated'
            : DateFormat('EEE, d MMM').format(DateTime.parse(key)),
        pulses: groups[key]!,
      ),
  ];
}
