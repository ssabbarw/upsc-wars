import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../daily_ca_admin_constants.dart';
import '../data/daily_ca_cloud_service.dart';
import '../domain/daily_ca_rank_models.dart';
import '../domain/daily_ca_scoring.dart';
import '../providers/daily_ca_providers.dart';

/// After a first Daily CA attempt: submit for AIR when ranks are on.
class DailyCaResultsScreen extends HookConsumerWidget {
  const DailyCaResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = useState<_SyncState>(_SyncState.loading);
    final submission = useState<DailyCaSubmission?>(null);
    final localScore = useState<double?>(null);
    final questionCount = useState<int>(0);
    final dateId = useState<String>('');
    final error = useState<String?>(null);
    final ranksAsync = ref.watch(dailyCaRanksRemoteEnabledProvider);
    final ranksOn = ranksAsync.asData?.value ?? false;
    final ranksReady = !ranksAsync.isLoading;

    useEffect(() {
      var cancelled = false;
      if (!ranksReady) return () {};
      unawaited(() async {
        try {
          final load = await ref.read(loadSessionUseCaseProvider.future);
          final session = await load.execute(sessionId);
          final iso = (session.topic ?? '').trim();
          if (iso.isEmpty) {
            throw StateError('Missing paper date on session');
          }
          if (cancelled) return;
          dateId.value = iso;
          questionCount.value = session.questions.length;

          final answers = <String, String>{};
          for (final q in session.questions) {
            final sel = q.selectedOption?.trim();
            if (sel != null && sel.isNotEmpty) {
              answers[q.uuid] = sel.toLowerCase();
            }
          }
          final limit = session.timeLimitSecs ?? 0;
          final remaining = session.savedExamRemainingSecs ?? 0;
          final elapsedMs =
              ((limit - remaining).clamp(0, limit > 0 ? limit : 0) * 1000);

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (!ranksOn || uid == null) {
            var correct = 0;
            var wrong = 0;
            for (final q in session.questions) {
              final sel = q.selectedOption?.trim();
              if (sel == null || sel.isEmpty) continue;
              if (sel.toLowerCase() == q.correctOption.trim().toLowerCase()) {
                correct++;
              } else {
                wrong++;
              }
            }
            localScore.value =
                correct * DailyCaScoring.pointsCorrect -
                wrong * DailyCaScoring.pointsWrong;
            syncState.value = _SyncState.ready;
            return;
          }

          const cloud = DailyCaCloudService();
          final result = await cloud.submit(
            dateId: iso,
            answers: answers,
            elapsedMs: elapsedMs,
            displayName: FirebaseAuth.instance.currentUser?.displayName?.trim(),
          );
          if (cancelled) return;
          if (!result.ok) {
            error.value = result.errorMessage ?? 'Submit failed';
            syncState.value = _SyncState.error;
            return;
          }

          submission.value = DailyCaSubmission(
            uid: uid,
            mode: result.mode ?? 'live',
            score: result.score ?? 0,
            correct: result.correct ?? 0,
            wrong: result.wrong ?? 0,
            unanswered: result.unanswered ?? 0,
            elapsedMs: result.elapsedMs ?? elapsedMs,
            air: result.air,
            percentile: result.percentile,
            participantCount: result.participantCount,
            displayName: FirebaseAuth.instance.currentUser?.displayName?.trim(),
          );
          syncState.value = _SyncState.ready;
        } on Object catch (e) {
          if (cancelled) return;
          error.value = e.toString();
          syncState.value = _SyncState.error;
        }
      }());
      return () => cancelled = true;
    }, [sessionId, ranksOn, ranksReady]);

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Paper results',
          style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: switch (syncState.value) {
          _SyncState.loading => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting your answers…'),
              ],
            ),
          ),
          _SyncState.error => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                error.value ?? 'Something went wrong',
                style: AppTextStyles.body().copyWith(color: AppColors.wrong),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
          _SyncState.ready => _ReadyBody(
            dateId: dateId.value,
            sessionId: sessionId,
            submission: submission.value,
            localScore: localScore.value,
            questionCount: questionCount.value,
            ranksOn: ranksOn,
            signedIn: FirebaseAuth.instance.currentUser != null,
          ),
        },
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.dateId,
    required this.sessionId,
    required this.submission,
    required this.localScore,
    required this.questionCount,
    required this.ranksOn,
    required this.signedIn,
  });

  final String dateId;
  final String sessionId;
  final DailyCaSubmission? submission;
  final double? localScore;
  final int questionCount;
  final bool ranksOn;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxPts = DailyCaScoring.maxPoints(questionCount);
    final score = submission?.score ?? localScore;
    final ranked = submission?.hasOfficialRank == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ranked) ...[
          Text(
            'ALL-INDIA RANK',
            style: AppTextStyles.caption().copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${submission!.air}',
            style: AppTextStyles.h1().copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 56,
              height: 1,
            ),
          ),
          if (submission!.participantCount != null) ...[
            const SizedBox(height: 4),
            Text(
              'of ${submission!.participantCount}',
              style: AppTextStyles.body().copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'PERCENTILE',
                  value: submission!.percentile?.toStringAsFixed(1) ?? '—',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'SCORE',
                  value:
                      '${submission!.score.toStringAsFixed(2)}/${maxPts.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DailyCaScheduleHint.liveCopy(submission!.mode),
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          Text(
            'SCORE',
            style: AppTextStyles.caption().copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(score ?? 0).toStringAsFixed(2)}/${maxPts.toStringAsFixed(0)}',
            style: AppTextStyles.h1().copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 44,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !ranksOn
                ? 'Ranks are in preview.'
                : !signedIn
                ? 'Sign in from Profile to join today\'s All-India Rank.'
                : submission?.mode == 'unranked'
                ? 'Unranked · this paper\'s Champion is already locked.'
                : 'Submitted.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        if (ranksOn && signedIn && dateId.isNotEmpty) ...[
          FilledButton(
            onPressed: () => context.push(dailyCaLeaderboardRoute(dateId)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: const Text('Today\'s leaderboard'),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton(
          onPressed: () => context.push('/results/$sessionId'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: const Text('Review answers'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => context.go('/'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class DailyCaScheduleHint {
  static String liveCopy(String mode) {
    if (mode == 'unranked') {
      return 'Unranked · Champion already locked.';
    }
    return 'This rank includes everyone who has finished so far. Open ranks again to refresh. Champion locks at 6 AM.';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

enum _SyncState { loading, ready, error }
