import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/series_stats.dart';
import '../domain/start_series_test.dart';
import '../domain/test_series_models.dart';
import '../providers/test_series_providers.dart';
import 'series_paywall_sheet.dart';
import 'series_test_tile.dart';

/// A [SeriesTestTile] wired to everything a tap can mean: paywall, review,
/// practise-again, resume, start, or "not unlocked yet".
class SeriesTestRow extends ConsumerWidget {
  const SeriesTestRow({
    super.key,
    required this.bundle,
    required this.test,
    required this.owned,
    required this.stats,
  });

  final SeriesBundle bundle;
  final SeriesTest test;
  final bool owned;
  final SeriesStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress =
        ref.watch(seriesInProgressProvider(bundle.info.id)).value ??
        const <String, String>{};
    final now = DateTime.now();
    final attempt = stats.attempts[test.id];
    final isInProgress = inProgress.containsKey(test.id);
    return SeriesTestTile(
      test: test,
      state: seriesTileState(
        test: test,
        owned: owned,
        inProgress: isInProgress,
        attempt: attempt,
        now: now,
      ),
      attempt: attempt,
      now: now,
      onTap: () => unawaited(
        _onTap(context, ref, attempt: attempt, inProgress: isInProgress),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref, {
    required SeriesTestAttempt? attempt,
    required bool inProgress,
  }) async {
    final now = DateTime.now();
    if (!owned && !test.isFree) {
      await showSeriesPaywall(context: context, bundle: bundle);
      return;
    }
    if (attempt != null) {
      await _showAttemptSheet(context, ref, attempt);
      return;
    }
    if (!test.isAvailableAt(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${test.title}: ${seriesUnlockLabel(test, now)}.'),
        ),
      );
      return;
    }
    if (inProgress) {
      await _launch(context, ref);
      return;
    }
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => _StartSheet(test: test),
    );
    if (go == true && context.mounted) await _launch(context, ref);
  }

  Future<void> _launch(
    BuildContext context,
    WidgetRef ref, {
    bool practice = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await startSeriesTest(
        context: context,
        ref: ref,
        test: test,
        practice: practice,
      );
    } on SeriesTestOpenException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't load this test. Check your connection and try again.",
          ),
        ),
      );
    }
  }

  Future<void> _showAttemptSheet(
    BuildContext context,
    WidgetRef ref,
    SeriesTestAttempt attempt,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(test.title, style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Score ${seriesMarksLabel(attempt.netMarks, attempt.maxMarks)}  ·  '
                '${attempt.correct} correct, ${attempt.wrong} wrong, '
                '${attempt.unanswered} skipped',
                style: AppTextStyles.bodyMd(),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'review'),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review answers'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, 'practice'),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Practise again (not scored)'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'review') {
      unawaited(context.push('/history/${attempt.sessionId}'));
    } else {
      await _launch(context, ref, practice: true);
    }
  }
}

class _StartSheet extends StatelessWidget {
  const _StartSheet({required this.test});

  final SeriesTest test;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(test.title, style: AppTextStyles.h2()),
            if ((test.theme ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                test.theme!,
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _Fact(Icons.quiz_outlined, '${test.questionCount} questions'),
            _Fact(Icons.timer_outlined, '${test.durationMins} minutes, timed'),
            const _Fact(
              Icons.calculate_outlined,
              '+2 for correct, -0.66 for wrong',
            ),
            const _Fact(
              Icons.flag_outlined,
              'One scored attempt. Afterwards you can review it and practise '
              'again without affecting your stats.',
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Start test'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd())),
        ],
      ),
    );
  }
}
