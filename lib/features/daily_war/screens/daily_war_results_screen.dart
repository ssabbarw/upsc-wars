import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../daily_war_constants.dart';
import '../data/daily_war_cloud_service.dart';
import '../data/daily_war_firestore_paths.dart';
import '../domain/daily_war_badges.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/daily_war_streak.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// After the local test session completes, sync score to Cloud Functions and
/// show AIR (live) or practice score (unranked).
class DailyWarResultsScreen extends HookConsumerWidget {
  const DailyWarResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = useState<_SyncState>(_SyncState.loading);
    final score = useState<double?>(null);
    final submission = useState<DailyWarSubmission?>(null);
    final nextTopics = useState<List<DailyWarTopicRef>>(const []);
    final participantCount = useState<int?>(null);
    final questionCount = useState<int>(15);
    final warDateId = useState<String>('');
    final error = useState<String?>(null);

    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        try {
          final load = await ref.read(loadSessionUseCaseProvider.future);
          final session = await load.execute(sessionId);
          final dateId = (session.topic ?? '').trim();
          if (dateId.isEmpty) {
            throw StateError('Missing War date on session');
          }
          warDateId.value = dateId;
          final mode =
              DailyWarConstants.isUnrankedFeatureKey(
                session.analyticsFeatureKey,
              )
              ? 'unranked'
              : 'live';

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

          final displayName = FirebaseAuth.instance.currentUser?.displayName
              ?.trim();

          int? streakDays;
          String? tierId;
          if (mode == 'live') {
            final prefs = await ref.read(prefsServiceProvider.future);
            DailyWarStreak.reconcile(
              prefs: prefs,
              istNow: DateTime.now(), // offset applied on home; fine for submit
            );
            streakDays = DailyWarStreak.peekNextDays(
              prefs: prefs,
              dateId: dateId,
            );
            tierId = DailyWarBadges.tierIdForDays(streakDays);
          }

          const cloud = DailyWarCloudService();
          final result = await cloud.submit(
            dateId: dateId,
            answers: answers,
            elapsedMs: elapsedMs,
            mode: mode,
            displayName: displayName,
            warStreakDays: streakDays,
            tierId: tierId,
          );
          if (cancelled) return;
          if (!result.ok) {
            error.value = result.errorMessage ?? 'Submit failed';
            syncState.value = _SyncState.error;
            return;
          }
          score.value = result.score;

          if (result.badges.isNotEmpty) {
            final cache = await ref.read(dailyWarLocalCacheProvider.future);
            await cache.incrementBadgeCounts(result.badges);
            ref.invalidate(dailyWarBadgeTalliesProvider);
          }

          final warDate = DailyWarSchedule.parseIsoDate(dateId);
          unawaited(
            Analytics.track(
              ref,
              DailyWarSubmittedEvent(
                dateId: dateId,
                mode: mode,
                isGrand: DailyWarSchedule.isGrandWarDay(warDate),
                score: result.score ?? 0,
              ),
            ),
          );

          if (mode == 'live') {
            final prefs = await ref.read(prefsServiceProvider.future);
            DailyWarStreak.recordLivePlay(prefs: prefs, dateId: dateId);
            ref.invalidate(dailyWarStreakCountProvider);
          }

          final warDoc = await ref.read(dailyWarDocByIdProvider(dateId).future);
          nextTopics.value = warDoc?.nextTopics ?? const [];
          participantCount.value = warDoc?.participantCount;
          questionCount.value = warDoc?.questionCount ?? 15;

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final snap = await DailyWarFirestorePaths.submissionDoc(
              dateId,
              uid,
            ).get();
            if (snap.exists && snap.data() != null) {
              submission.value = DailyWarSubmission.fromMap(uid, snap.data()!);
            }
          }

          syncState.value = _SyncState.ready;
        } on Object catch (e) {
          if (cancelled) return;
          error.value = e.toString();
          syncState.value = _SyncState.error;
        }
      }());
      return () => cancelled = true;
    }, [sessionId]);

    return Scaffold(
      backgroundColor: DwColors.surface,
      appBar: AppBar(
        backgroundColor: DwColors.surface,
        foregroundColor: DwColors.onDark,
        title: Text(
          'Static War results',
          style: DwText.dm(size: 18, weight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: switch (syncState.value) {
          _SyncState.loading => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: DwColors.crimsonBright),
                const SizedBox(height: 16),
                Text(
                  'Submitting your answers…',
                  style: DwText.body(color: DwColors.onDark),
                ),
              ],
            ),
          ),
          _SyncState.error => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                error.value ?? 'Something went wrong',
                style: DwText.body(color: DwColors.crimsonBright),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  backgroundColor: DwColors.crimson,
                ),
                child: Text('Home', style: DwText.cta()),
              ),
            ],
          ),
          _SyncState.ready => _ReadyBody(
            dateId: warDateId.value,
            submission: submission.value,
            score: score.value,
            nextTopics: nextTopics.value,
            participantCount: participantCount.value,
            questionCount: questionCount.value,
          ),
        },
      ),
    );
  }
}

class _ReadyBody extends ConsumerWidget {
  const _ReadyBody({
    required this.dateId,
    required this.submission,
    required this.score,
    required this.nextTopics,
    required this.participantCount,
    required this.questionCount,
  });

  final String dateId;
  final DailyWarSubmission? submission;
  final double? score;
  final List<DailyWarTopicRef> nextTopics;
  final int? participantCount;
  final int questionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countEnabled =
        ref.watch(dailyWarLobbyCountRemoteEnabledProvider).asData?.value ??
        true;
    final minVisible =
        ref.watch(dailyWarMinVisibleLobbyCountRemoteProvider).asData?.value ??
        200;
    final ofN = DailyWarCopy.formatVisibleCount(
      raw: participantCount,
      enabled: countEnabled,
      minVisible: minVisible,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (submission?.hasOfficialRank == true) ...[
          Text('ALL-INDIA RANK', style: DwText.meta()),
          const SizedBox(height: 4),
          Text('${submission!.air}', style: DwText.heroNumber()),
          if (ofN != null) Text('of $ofN', style: DwText.body()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                  label: 'PERCENTILE',
                  value: submission!.percentile?.toStringAsFixed(1) ?? '—',
                ),
              ),
              Expanded(
                child: _ResultStat(
                  label: 'SCORE',
                  value:
                      '${submission!.score.toStringAsFixed(2)}/$questionCount',
                ),
              ),
            ],
          ),
        ] else ...[
          Text('SCORE', style: DwText.meta()),
          const SizedBox(height: 4),
          Text(
            '${(score ?? submission?.score)?.toStringAsFixed(2) ?? '—'}'
            '/$questionCount',
            style: DwText.heroNumber(),
          ),
          Text(
            submission?.mode == 'unranked'
                ? 'Unranked · not an official AIR'
                : 'Submitted · AIR will be ready at 9:40 PM IST. '
                      'We\'ll notify you.',
            style: DwText.body(),
          ),
        ],
        if (nextTopics.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Tomorrow', style: DwText.meta()),
          const SizedBox(height: 6),
          Text(
            DailyWarCopy.compactTopics(nextTopics),
            style: DwText.body(color: DwColors.onDark),
          ),
        ],
        const Spacer(),
        if (submission?.hasOfficialRank == true && dateId.isNotEmpty) ...[
          FilledButton(
            onPressed: () => context.push(dailyWarLeaderboardRoute(dateId)),
            style: FilledButton.styleFrom(
              backgroundColor: DwColors.teal,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Tonight\'s leaderboard', style: DwText.cta()),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: () => context.go('/'),
          style: FilledButton.styleFrom(
            backgroundColor: DwColors.crimson,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Done', style: DwText.cta()),
        ),
        TextButton(
          onPressed: () => context.push(dailyWarHistoryRoute()),
          child: Text(
            'History',
            style: DwText.dm(
              size: 13,
              weight: FontWeight.w600,
              color: DwColors.onDarkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DwText.stamp()),
        Text(value, style: DwText.dm(size: 20, weight: FontWeight.w700)),
      ],
    );
  }
}

enum _SyncState { loading, ready, error }
