import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../features/home/providers/auth_providers.dart';
import '../../../shared/widgets/shimmer_box.dart';
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
import '../../../l10n/l10n.dart';

class DailyWarLobbyScreen extends HookConsumerWidget {
  const DailyWarLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(dailyWarRemoteEnabledProvider);
    return available.when(
      loading: () => const _DailyWarLobbySkeleton(),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text(DailyWarCopy.programName)),
        body: Center(child: Text(context.l10n.dwNotAvailable)),
      ),
      data: (on) {
        if (!on) {
          return Scaffold(
            appBar: AppBar(title: const Text(DailyWarCopy.programName)),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  context.l10n.dwNotAvailableAccount,
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

/// Dark lobby-shaped placeholder while Remote Config resolves.
class _DailyWarLobbySkeleton extends StatelessWidget {
  const _DailyWarLobbySkeleton();

  static const _bone = Color(0xFF2A2A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DwColors.surface,
      appBar: AppBar(
        backgroundColor: DwColors.surface,
        foregroundColor: DwColors.onDark,
        title: const ShimmerBox(width: 110, height: 18, color: _bone),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 88, height: 10, color: _bone),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  const Expanded(
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 36,
                      borderRadius: 18,
                      color: _bone,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const ShimmerBox(width: 160, height: 12, color: _bone),
            const SizedBox(height: 10),
            const ShimmerBox(width: double.infinity, height: 22, color: _bone),
            const SizedBox(height: 8),
            const ShimmerBox(width: 220, height: 22, color: _bone),
            const SizedBox(height: 16),
            const ShimmerBox(
              width: double.infinity,
              height: 120,
              borderRadius: 16,
              color: _bone,
            ),
            const SizedBox(height: 24),
            const ShimmerBox(
              width: double.infinity,
              height: 48,
              borderRadius: 12,
              color: _bone,
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyWarLobbyBody extends HookConsumerWidget {
  const _DailyWarLobbyBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDoc = ref.watch(dailyWarTodayDocProvider);
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

    if (todayDoc.isLoading && snap.doc == null) {
      return const _DailyWarLobbySkeleton();
    }

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
    final accountSignedIn = AuthSession.isAccountSignedIn(
      ref.watch(authStateChangesProvider).asData?.value,
    );

    final countShown = DailyWarCopy.formatVisibleCount(
      raw: snap.phase == DailyWarPhase.lobby
          ? (liveCounts.lobby > 0 ? liveCounts.lobby : null)
          : (liveCounts.writing > 0 ? liveCounts.writing : null),
      enabled: countEnabled,
      minVisible: minVisible,
    );

    Future<void> enterWar({required bool unranked}) async {
      if (launching.value) return;
      launching.value = true;
      try {
        var doc = snap.doc;
        doc ??= await ref.read(dailyWarTodayDocProvider.notifier).refresh();
        if (doc == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.dwPaperNotLoaded)),
            );
          }
          return;
        }
        if (!context.mounted) return;
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
          isGrand ? DailyWarCopy.grandEventName : DailyWarCopy.dailyEventName,
          style: DwText.dm(size: 18, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.dwHowWorks(DailyWarCopy.programName),
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
              context.l10n.dwHistory,
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
                ? context.l10n.dwLobbyOpen
                : snap.phase == DailyWarPhase.liveJoinable
                ? context.l10n.dwEventIsLiveCaps(
                    DailyWarCopy.eventNameCaps(isGrand: isGrand),
                  )
                : _statusEyebrow(snap.phase, isGrand: isGrand),
            style: DwText.eyebrow(),
          ),
          const SizedBox(height: 12),
          DailyWarWeekStrip(referenceIst: ist),
          const SizedBox(height: 16),
          if (snap.phase == DailyWarPhase.restDay) ...[
            Text(context.l10n.dwSundayOffTitle, style: DwText.topic()),
            const SizedBox(height: 8),
            Text(
              context.l10n.dwNoLiveNext(DailyWarCopy.dailyEventName),
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
                  context.l10n.dwPlusMore(topics.length - 2),
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
                    ? context.l10n.dwSeeAllTopics(topics.length)
                    : context.l10n.dwPracticeTopics,
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
                        ? context.l10n.dwStartsIn(
                            DailyWarSchedule.formatCountdown(untilStart),
                          )
                        : canEnter
                        ? context.l10n.dwJoinUntilLeft(mmSs(untilLate))
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
                          ? context.l10n.dwAspirantsInLobby
                          : context.l10n.dwWritingNow,
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
                    ? context.l10n.dwSeeYourAir(snap.submission!.air ?? 0)
                    : context.l10n.dwOpenHistory,
                onPressed: () => context.push(dailyWarHistoryRoute()),
              )
            else if (canEnter)
              _DwButton(
                label: launching.value
                    ? context.l10n.dwStarting
                    : accountSignedIn
                    ? context.l10n.dwJoinNow
                    : context.l10n.dwSignInJoin,
                onPressed: launching.value
                    ? null
                    : () => unawaited(enterWar(unranked: false)),
                loading: launching.value,
              )
            else if (snap.phase == DailyWarPhase.lobby)
              _DwButton(
                label: untilStart.isNegative
                    ? context.l10n.dwStarting
                    : context.l10n.dwStartsIn(mmSs(untilStart)),
              )
            else if (snap.phase == DailyWarPhase.liveLocked)
              _DwButton(label: context.l10n.dwCantJoinNow)
            else if (snap.phase == DailyWarPhase.resultsReady ||
                snap.phase == DailyWarPhase.resultsPending)
              _DwButton(
                label: launching.value
                    ? context.l10n.dwStarting
                    : accountSignedIn
                    ? context.l10n.dwAttemptUnranked
                    : context.l10n.dwSignInAttempt,
                filled: false,
                onPressed: launching.value
                    ? null
                    : () => unawaited(enterWar(unranked: true)),
              )
            else
              Text(context.l10n.dwComeBack859, style: DwText.body()),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              context.l10n.resultsBackToHome,
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

  String _statusEyebrow(DailyWarPhase phase, {required bool isGrand}) {
    switch (phase) {
      case DailyWarPhase.resultsReady:
        return appL10n.dwResultsReady;
      case DailyWarPhase.resultsPending:
        return appL10n.dwResultsEyebrow;
      case DailyWarPhase.liveLocked:
        return appL10n.dwInProgress;
      case DailyWarPhase.restDay:
        return appL10n.dwSundayOff;
      default:
        return DailyWarCopy.eventNameCaps(isGrand: isGrand);
    }
  }

  String _statusCopy(DailyWarPhase phase, {required String rankClock}) {
    switch (phase) {
      case DailyWarPhase.restDay:
        return appL10n.dwNoPaperNext(DailyWarCopy.dailyEventName);
      case DailyWarPhase.preAnnounce:
      case DailyWarPhase.morning:
      case DailyWarPhase.countdown:
        return appL10n.dwPrepareToday;
      case DailyWarPhase.liveLocked:
        return appL10n.dwLateClosedAirAt(rankClock);
      case DailyWarPhase.resultsPending:
        return appL10n.dwRanksCalculating;
      case DailyWarPhase.resultsReady:
        return appL10n.dwResultsReadyTitle;
      case DailyWarPhase.lobby:
      case DailyWarPhase.liveJoinable:
        return appL10n.dwReady;
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
                disabledBackgroundColor: DwColors.crimson.withValues(
                  alpha: 0.45,
                ),
                disabledForegroundColor: DwColors.onDark.withValues(
                  alpha: 0.85,
                ),
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
