import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';

/// Full-screen MCQ experience for a Fomo Pulse.
///
/// Tutor-like flow: tap option, see verdict + explanation instantly, then CTA.
class FomoPulseMcqScreen extends HookConsumerWidget {
  const FomoPulseMcqScreen({
    super.key,
    required this.pulseId,
    this.initialSelectedOption,
  });

  final String pulseId;
  final String? initialSelectedOption;

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
                  'Could not load this CA Shot.',
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
        data: (data) => _FomoPulseTutorBody(
          pulse: data.pulse,
          existingAttempt: data.attempt,
          initialSelectedOption: initialSelectedOption,
        ),
      ),
    );
  }
}

class _FomoPulseTutorBody extends HookConsumerWidget {
  const _FomoPulseTutorBody({
    required this.pulse,
    required this.existingAttempt,
    required this.initialSelectedOption,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? existingAttempt;
  final String? initialSelectedOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHi = watchAppLanguage(ref) == 'hi';
    final question = pulse.question.localized(isHi);
    final openedAt = useMemoized(DateTime.now);
    final attemptedOnOpen = existingAttempt?.attempted == true;
    final picked = useState<String?>(existingAttempt?.selectedOption);
    final isAutoSubmitting = useState(false);

    final selected = picked.value ?? '';
    final revealed = selected.isNotEmpty;
    final isCorrect =
        selected.toLowerCase() == question.correctOption.toLowerCase();
    final stats = pulse.communityStats(
      minAttempts: FomoPulseConstants.minStatsAttempts,
    );
    final valueAddPoints = isHi && pulse.upscPointsHi.isNotEmpty
        ? pulse.upscPointsHi
        : pulse.upscPoints;

    Future<void> syncAttempt(String option) async {
      final secs = DateTime.now().difference(openedAt).inSeconds.clamp(1, 600);
      final repo = ref.read(fomoPulseRepositoryProvider);
      final cloud = ref.read(fomoPulseCloudServiceProvider);
      final local = FomoPulseSubmitResult(
        isCorrect: option.toLowerCase() == question.correctOption.toLowerCase(),
        selectedOption: option,
        correctOption: question.correctOption,
        alreadyAttempted: false,
        timeSpentSecs: secs,
      );
      await repo.recordLocalAttempt(
        pulseId: pulse.pulseId,
        result: local,
        updateCommunityCounts: false,
      );
      try {
        final remote = await cloud.submitAttempt(
          pulseId: pulse.pulseId,
          selectedOption: option,
          timeSpentSecs: secs,
        );
        await repo.recordLocalAttempt(pulseId: pulse.pulseId, result: remote);
        if (!remote.alreadyAttempted) {
          unawaited(AdminDashboardWriterService().recordFomoPulseEngagement());
        }
      } catch (_) {}
      ref.invalidate(fomoPulseDetailProvider(pulse.pulseId));
      ref.invalidate(fomoPulseHistoryProvider);
    }

    Future<void> onPick(String option) async {
      if (revealed) return;
      picked.value = option;
      if (!attemptedOnOpen) {
        await syncAttempt(option);
      }
    }

    useEffect(() {
      final option = initialSelectedOption?.trim().toLowerCase();
      if (attemptedOnOpen || option == null || option.isEmpty || revealed) {
        return null;
      }
      Future<void>(() async {
        isAutoSubmitting.value = true;
        await onPick(option);
        if (context.mounted) {
          isAutoSubmitting.value = false;
        }
      });
      return null;
    }, [initialSelectedOption, attemptedOnOpen]);

    Widget optionTile(String key, String text) {
      final k = key.toLowerCase();
      final chosen = selected.toLowerCase() == k;
      final correct = question.correctOption.toLowerCase() == k;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final scheme = Theme.of(context).colorScheme;
      final bg = !revealed
          ? scheme.surface
          : correct
          ? (isDark ? AppColors.correctBgDark : AppColors.correctBg)
          : chosen
          ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg)
          : scheme.surface;
      final border = !revealed
          ? scheme.outlineVariant
          : correct
          ? AppColors.correct
          : chosen
          ? AppColors.wrong
          : scheme.outlineVariant;
      final fg = !revealed
          ? scheme.onSurface
          : correct
          ? (isDark ? AppColors.correctTextDark : AppColors.correctText)
          : chosen
          ? (isDark ? AppColors.wrongTextDark : AppColors.wrongText)
          : scheme.onSurface;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: revealed ? null : () => unawaited(onPick(k)),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: border, width: revealed ? 1.5 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: border.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      key.toUpperCase(),
                      style: AppTextStyles.labelSm().copyWith(color: fg),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTextStyles.option().copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (isAutoSubmitting.value) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          question.stemText,
          style: AppTextStyles.body().copyWith(height: 1.35),
        ),
        const SizedBox(height: AppSpacing.md),
        optionTile('a', question.optionA),
        optionTile('b', question.optionB),
        optionTile('c', question.optionC),
        optionTile('d', question.optionD),
        if (!revealed) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick an option to see answer and explanation.',
            style: AppTextStyles.caption().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (revealed) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            isCorrect ? 'Correct!' : 'Incorrect',
            style: AppTextStyles.label().copyWith(
              color: isCorrect ? AppColors.correct : AppColors.wrong,
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              stats.trapLine,
              style: AppTextStyles.caption().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (question.finalExplanation.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Explanation', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                question.finalExplanation,
                style: AppTextStyles.bodySm().copyWith(height: 1.45),
              ),
            ),
          ],
          if (question.strongDistractor.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Strong distractor', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(text: question.strongDistractor),
          ],
          if (question.eliminationLogic.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Elimination steps', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            _BulletCard(lines: question.eliminationLogic),
          ],
          if (question.statementAnalysis.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Statement analysis', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            _StatementAnalysisCard(items: question.statementAnalysis),
          ],
          if (question.upscTrapExplanation.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Trap used here', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(text: question.upscTrapExplanation),
          ],
          if (valueAddPoints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Value-add points', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            _BulletCard(lines: valueAddPoints),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to CA Shot'),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text, style: AppTextStyles.bodySm().copyWith(height: 1.4)),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            if (line.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '• $line',
                  style: AppTextStyles.bodySm().copyWith(height: 1.4),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatementAnalysisCard extends StatelessWidget {
  const _StatementAnalysisCard({required this.items});

  final List<FomoPulseStatementAnalysisItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            if (item.statement.trim().isNotEmpty ||
                item.reason.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.isCorrect ? '[Correct]' : '[Wrong]'} ${item.statement}',
                      style: AppTextStyles.bodySm().copyWith(
                        fontWeight: FontWeight.w700,
                        color: item.isCorrect
                            ? AppColors.correct
                            : AppColors.wrong,
                      ),
                    ),
                    if (item.reason.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.reason,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
