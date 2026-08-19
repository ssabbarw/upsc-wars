import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../daily_war_constants.dart';
import '../data/daily_war_cloud_service.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/start_daily_war_attempt.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';
import '../widgets/daily_war_help_sheet.dart';
import '../widgets/daily_war_topics_sheet.dart';
import '../widgets/daily_war_week_strip.dart';

class DailyWarLobbyScreen extends HookConsumerWidget {
  const DailyWarLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(dailyWarRemoteEnabledProvider);
    return available.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Daily War')),
        body: const Center(child: Text('Daily War is not available.')),
      ),
      data: (on) {
        if (!on) {
          return Scaffold(
            appBar: AppBar(title: const Text('Daily War')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Daily War is not available on this account yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return const _DailyWarLobbyBody();
      },
    );
  }
}

class _DailyWarLobbyBody extends HookConsumerWidget {
  const _DailyWarLobbyBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final launching = useState(false);
    final tick = useState(0);
    final countEnabled =
        ref.watch(dailyWarLobbyCountRemoteEnabledProvider).asData?.value ??
        true;
    final minVisible =
        ref.watch(dailyWarMinVisibleLobbyCountRemoteProvider).asData?.value ??
        DailyWarSchedule.minVisibleParticipantCount;
    final liveCounts =
        ref.watch(dailyWarLiveCountsProvider).asData?.value ??
        const DailyWarLiveCounts.empty();

    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, const []);
    tick.value;

    final joinedLobbyDate = useRef<String?>(null);
    useEffect(() {
      if (snap.phase != DailyWarPhase.lobby &&
          snap.phase != DailyWarPhase.liveJoinable) {
        return null;
      }
      if (joinedLobbyDate.value == snap.dateId) return null;
      joinedLobbyDate.value = snap.dateId;
      unawaited(const DailyWarCloudService().joinLobby(dateId: snap.dateId));
      return null;
    }, [snap.dateId, snap.phase]);

    // When the lobby/live phase opens, force-refresh the doc if questions
    // haven't loaded yet. The doc is fetched once per session on app open
    // (before 9 PM, questionUuids is still empty). Without this refresh the
    // Join button shows but immediately errors with "Questions publish just
    // before 9 PM."
    final refreshedForDate = useRef<String?>(null);
    useEffect(() {
      final phase = snap.phase;
      final isLobbyOrLive = phase == DailyWarPhase.lobby ||
          phase == DailyWarPhase.liveJoinable;
      if (!isLobbyOrLive) return null;
      final needsQuestions = snap.doc == null || snap.doc!.questionUuids.isEmpty;
      if (!needsQuestions) return null;
      if (refreshedForDate.value == snap.dateId) return null;
      refreshedForDate.value = snap.dateId;
      unawaited(ref.read(dailyWarTodayDocProvider.notifier).refresh());
      return null;
    }, [snap.dateId, snap.phase, snap.doc?.questionUuids.isEmpty]);

    final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
    final utc = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch + offset,
      isUtc: true,
    );
    final ist = DailyWarSchedule.nowIst(utc);
    final warDate = DailyWarSchedule.warDateFor(ist);
    final qCount =
        snap.doc?.questionCount ??
        DailyWarSchedule.questionCountForDate(warDate);
    final start = DailyWarSchedule.startAtForDate(warDate);
    final rankTarget = DailyWarSchedule.rankTargetAt(warDate);
    final lateClose = DailyWarSchedule.lateJoinClosesAt(warDate);
    final untilStart = start.difference(ist);
    final untilLate = lateClose.difference(ist);
    final canEnter = snap.phase == DailyWarPhase.liveJoinable;
    final alreadyDone = snap.submission != null;
    final isGrand = snap.doc?.isGrand == true;
    final topics = snap.doc?.topics ?? const [];

    final countShown = DailyWarCopy.formatVisibleCount(
      raw: snap.phase == DailyWarPhase.lobby
          ? (liveCounts.lobby > 0 ? liveCounts.lobby : null)
          : (liveCounts.writing > 0 ? liveCounts.writing : null),
      enabled: countEnabled,
      minVisible: minVisible,
    );

    Future<void> enterWar({required bool unranked}) async {
      if (launching.value) return;
      final doc = snap.doc;
      if (doc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tonight\'s War is not ready yet.')),
        );
        return;
      }

      launching.value = true;
      try {
        await startDailyWarAttempt(
          context: context,
          ref: ref,
          doc: doc,
          unranked: unranked,
          istNow: ist,
        );
      } finally {
        launching.value = false;
      }
    }

    String mmSs(Duration d) {
      final full = DailyWarSchedule.formatCountdown(d);
      return full.length > 5 ? full.substring(3) : full;
    }

    return Scaffold(
      backgroundColor: DwColors.surface,
      appBar: AppBar(
        backgroundColor: DwColors.surface,
        foregroundColor: DwColors.onDark,
        title: Text(
          isGrand ? 'Grand War' : 'Daily War',
          style: DwText.dm(size: 18, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'How Daily War works',
            onPressed: () => unawaited(showDailyWarHelpSheet(context)),
            icon: const Icon(
              Icons.help_outline_rounded,
              color: DwColors.onDarkMuted,
              size: 22,
            ),
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            snap.phase == DailyWarPhase.lobby
                ? 'LOBBY OPEN'
                : snap.phase == DailyWarPhase.liveJoinable
                ? 'WAR IS LIVE'
                : _statusEyebrow(snap.phase),
            style: DwText.eyebrow(),
          ),
          const SizedBox(height: 12),
          DailyWarWeekStrip(referenceIst: ist),
          const SizedBox(height: 16),
          if (snap.phase == DailyWarPhase.restDay) ...[
            Text('Sunday off', style: DwText.topic()),
            const SizedBox(height: 8),
            Text(
              'No live paper today. Next War is Monday at 9:00 PM IST.',
              style: DwText.body(),
            ),
          ] else if (topics.isEmpty)
            Text(DailyWarCopy.compactTopics(topics), style: DwText.topic())
          else ...[
            Text(
              DailyWarCopy.subjectsLine(topics).toUpperCase(),
              style: DwText.subject(color: DwColors.crimsonBright),
            ),
            const SizedBox(height: 6),
            for (final t in topics.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(t.topic, style: DwText.topic()),
              ),
            if (topics.length > 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '+ ${topics.length - 2} more',
                  style: DwText.dm(
                    size: 13,
                    weight: FontWeight.w600,
                    color: DwColors.onDarkDim,
                  ),
                ),
              ),
            GestureDetector(
              onTap: () =>
                  showDailyWarTopicsSheet(context: context, topics: topics),
              child: Text(
                topics.length > 2
                    ? 'See all ${topics.length} topics →'
                    : 'Practice these topics →',
                style: DwText.dm(
                  size: 13,
                  weight: FontWeight.w700,
                  color: DwColors.crimsonBright,
                ),
              ),
            ),
          ],
          if (snap.phase != DailyWarPhase.restDay) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DwColors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DwColors.borderOnDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snap.phase == DailyWarPhase.lobby
                        ? 'Starts in ${DailyWarSchedule.formatCountdown(untilStart)}'
                        : canEnter
                        ? 'Join until 9:10 · ${mmSs(untilLate)} left'
                        : _statusCopy(
                            snap.phase,
                            rankClock: DailyWarSchedule.formatClock(rankTarget),
                          ),
                    style: DwText.dm(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DailyWarCopy.rulesLineLobby(
                      questionCount: qCount,
                      isGrand: isGrand,
                    ),
                    style: DwText.body(),
                  ),
                  if (countShown != null &&
                      (snap.phase == DailyWarPhase.lobby ||
                          snap.phase == DailyWarPhase.liveJoinable)) ...[
                    const SizedBox(height: 14),
                    Text(countShown, style: DwText.heroNumber()),
                    Text(
                      snap.phase == DailyWarPhase.lobby
                          ? 'aspirants in the lobby'
                          : 'writing right now',
                      style: DwText.body(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (alreadyDone)
              _DwButton(
                label: snap.submission?.hasOfficialRank == true
                    ? 'See your AIR ${snap.submission!.air}'
                    : 'Open History',
                onPressed: () => context.push(dailyWarHistoryRoute()),
              )
            else if (canEnter)
              _DwButton(
                label: launching.value ? 'Starting…' : 'Join now',
                onPressed: launching.value
                    ? null
                    : () => unawaited(enterWar(unranked: false)),
                loading: launching.value,
              )
            else if (snap.phase == DailyWarPhase.lobby)
              const _DwButton(label: 'Starts at 9:00 PM')
            else if (snap.phase == DailyWarPhase.resultsReady ||
                snap.phase == DailyWarPhase.resultsPending)
              _DwButton(
                label: 'Attempt unranked',
                filled: false,
                onPressed: launching.value
                    ? null
                    : () => unawaited(enterWar(unranked: true)),
              )
            else
              Text(
                'Come back at 8:59 PM IST to enter the lobby.',
                style: DwText.body(),
              ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Back to home',
              style: DwText.dm(
                size: 13,
                weight: FontWeight.w600,
                color: DwColors.onDarkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusEyebrow(DailyWarPhase phase) {
    switch (phase) {
      case DailyWarPhase.resultsReady:
        return 'RESULTS READY';
      case DailyWarPhase.resultsPending:
        return 'RESULTS';
      case DailyWarPhase.liveLocked:
        return 'IN PROGRESS';
      case DailyWarPhase.restDay:
        return 'SUNDAY OFF';
      default:
        return 'DAILY WAR';
    }
  }

  String _statusCopy(DailyWarPhase phase, {required String rankClock}) {
    switch (phase) {
      case DailyWarPhase.restDay:
        return 'No paper today · next War Monday 9:00 PM';
      case DailyWarPhase.preAnnounce:
      case DailyWarPhase.morning:
      case DailyWarPhase.countdown:
        return 'Prepare today · lobby opens 8:59 PM';
      case DailyWarPhase.liveLocked:
        return 'Late join closed · AIR at $rankClock';
      case DailyWarPhase.resultsPending:
        return 'Ranks calculating…';
      case DailyWarPhase.resultsReady:
        return 'Results ready';
      case DailyWarPhase.lobby:
      case DailyWarPhase.liveJoinable:
        return 'Ready';
    }
  }
}

class _DwButton extends StatelessWidget {
  const _DwButton({
    required this.label,
    this.onPressed,
    this.filled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: DwColors.crimson,
                foregroundColor: DwColors.onDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DwColors.onDark,
                      ),
                    )
                  : Text(label, style: DwText.cta()),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DwColors.onDark,
                side: const BorderSide(color: DwColors.borderOnDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: DwText.cta(color: DwColors.onDarkMuted),
              ),
            ),
    );
  }
}
