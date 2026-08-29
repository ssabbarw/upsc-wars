import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_coverage.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_explainer_sheet.dart';
import 'daily_war_sunday_card.dart';
import 'daily_war_topics_sheet.dart';

/// Home hero for Daily War — three-band near-black card (design H1–H9).
class DailyWarHomeCard extends HookConsumerWidget {
  const DailyWarHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(dailyWarRemoteEnabledProvider);
    return enabled.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (on) {
        if (!on) return const SizedBox.shrink();
        return const _DailyWarHomeCardBody();
      },
    );
  }
}

class _DailyWarHomeCardBody extends HookConsumerWidget {
  const _DailyWarHomeCardBody();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = useState(0);
    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, const []);
    tick.value;

    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final todayDocAsync = ref.watch(dailyWarTodayDocProvider);
    final countEnabled =
        ref.watch(dailyWarLobbyCountRemoteEnabledProvider).asData?.value ??
        true;
    final minVisible =
        ref.watch(dailyWarMinVisibleLobbyCountRemoteProvider).asData?.value ??
        DailyWarSchedule.minVisibleParticipantCount;

    final isRest = snap.phase == DailyWarPhase.restDay;

    // Lobby presence is counted when the user opens the lobby screen — not from
    // home. Avoids a callable+tx per DAU on home.
    final liveCounts = countEnabled
        ? (ref.watch(dailyWarLiveCountsProvider).asData?.value ??
              const DailyWarLiveCounts.empty())
        : const DailyWarLiveCounts.empty();
    final historyBundle = ref
        .watch(dailyWarHistoryBundleProvider)
        .asData
        ?.value;

    final offset = effectiveServerTimeOffsetMs(
      ref.watch(dailyWarDebugClockProvider),
      ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0,
    );
    final utc = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch + offset,
      isUtc: true,
    );
    final ist = DailyWarSchedule.nowIst(utc);
    final warDate = DailyWarSchedule.warDateFor(ist);
    final start = DailyWarSchedule.startAtForDate(warDate);
    final lateClose = DailyWarSchedule.lateJoinClosesAt(warDate);
    final untilStart = start.difference(ist);
    final untilLateClose = lateClose.difference(ist);

    // Prefer the live AsyncValue so a stream error isn't mistaken for "still loading".
    final doc = todayDocAsync.asData?.value ?? snap.doc;
    final isGrand =
        doc?.isGrand == true || DailyWarSchedule.isGrandWarDay(warDate);
    final qCount =
        doc?.questionCount ?? DailyWarSchedule.questionCountForDate(warDate);
    final topics = doc?.topics ?? const <DailyWarTopicRef>[];
    final topicsLoadFailed = todayDocAsync.hasError && topics.isEmpty;
    final topicsLoading = todayDocAsync.isLoading && topics.isEmpty;

    final homeShownDate = useRef<String?>(null);
    useEffect(() {
      if (homeShownDate.value == snap.dateId) return null;
      homeShownDate.value = snap.dateId;
      unawaited(
        Analytics.track(
          ref,
          DailyWarHomeShownEvent(
            dateId: snap.dateId,
            phase: snap.phase.name,
            isGrand: isGrand,
          ),
        ),
      );
      unawaited(
        Analytics.track(
          ref,
          const FeatureViewedEvent(
            featureName: 'daily_war',
            subject: 'daily_war',
            source: 'home',
          ),
        ),
      );
      return null;
    }, [snap.dateId, snap.phase, isGrand]);

    final lobbyShown = DailyWarCopy.formatVisibleCount(
      raw: liveCounts.lobby > 0 ? liveCounts.lobby : null,
      enabled: countEnabled,
      minVisible: minVisible,
    );
    final writersShown = DailyWarCopy.formatVisibleCount(
      raw: liveCounts.writing > 0
          ? liveCounts.writing
          : (doc?.participantCount),
      enabled: countEnabled,
      minVisible: minVisible,
    );

    final historyWars = historyBundle?.wars ?? const <DailyWarDoc>[];
    final coverage = DailyWarCoverage.compute(
      historyWars: historyWars,
      tonightTopics: topics,
      tonightDoc: doc,
    );

    final simulatingClock =
        ref.watch(dailyWarDebugClockProvider) == DailyWarDebugClock.liveJoinable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (simulatingClock)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _DebugClockBanner(),
            ),
          Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRest
              ? null
              : snap.phase == DailyWarPhase.morning ||
                    snap.phase == DailyWarPhase.countdown ||
                    snap.phase == DailyWarPhase.preAnnounce
              ? () => unawaited(
                  showDailyWarExplainerSheet(
                    context: context,
                    topics: topics,
                    isGrand: isGrand,
                  ),
                )
              : snap.phase == DailyWarPhase.lobby ||
                    snap.phase == DailyWarPhase.liveJoinable ||
                    (snap.phase == DailyWarPhase.liveLocked &&
                        snap.submission == null)
              ? () => context.push(dailyWarLobbyRoute())
              : () => context.push(dailyWarHistoryRoute()),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isRest
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF151821),
                        Color(0xFF131417),
                        Color(0xFF1A1520),
                      ],
                    )
                  : null,
              color: isRest ? null : DwColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRest ? const Color(0x22A8B4FF) : DwColors.borderOnDark,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isRest
                  ? const DailyWarSundayCard()
                  : _HeroBody(
                      snap: snap,
                      isGrand: isGrand,
                      qCount: qCount,
                      topics: topics,
                      topicsLoadFailed: topicsLoadFailed,
                      topicsLoading: topicsLoading,
                      untilStart: untilStart,
                      untilLateClose: untilLateClose,
                      lobbyShown: lobbyShown,
                      writersShown: writersShown,
                      warDate: warDate,
                      coverage: coverage,
                    ),
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _DebugClockBanner extends StatelessWidget {
  const _DebugClockBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFC46B)),
      ),
      child: const Text(
        'DEBUG CLOCK · 9:05 PM IST (late join). Turn off in Settings → Static War.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9A5B00),
        ),
      ),
    );
  }
}

class _HeroBody extends StatelessWidget {
  const _HeroBody({
    required this.snap,
    required this.isGrand,
    required this.qCount,
    required this.topics,
    required this.topicsLoadFailed,
    required this.topicsLoading,
    required this.untilStart,
    required this.untilLateClose,
    required this.lobbyShown,
    required this.writersShown,
    required this.warDate,
    required this.coverage,
  });

  final DailyWarHomeSnapshot snap;
  final bool isGrand;
  final int qCount;
  final List<DailyWarTopicRef> topics;
  final bool topicsLoadFailed;
  final bool topicsLoading;
  final Duration untilStart;
  final Duration untilLateClose;
  final String? lobbyShown;
  final String? writersShown;
  final DateTime warDate;
  final ({int covered, int tonightAdds, int total}) coverage;

  @override
  Widget build(BuildContext context) {
    switch (snap.phase) {
      case DailyWarPhase.restDay:
        // Rendered by [DailyWarSundayCard] in the home card body.
        return const SizedBox.shrink();
      case DailyWarPhase.resultsReady:
        if (snap.submission?.hasOfficialRank == true) {
          return _ResultPlayed(
            snap: snap,
            warDate: warDate,
            writersShown: writersShown,
          );
        }
        return _ResultSatOut(snap: snap, writersShown: writersShown);
      case DailyWarPhase.resultsPending:
        return _ResultsPending(snap: snap, topics: topics);
      case DailyWarPhase.liveLocked:
        return _LiveLocked(
          snap: snap,
          topics: topics,
          writersShown: writersShown,
          isGrand: isGrand,
        );
      case DailyWarPhase.liveJoinable:
        return _LiveJoinable(
          topics: topics,
          untilLateClose: untilLateClose,
          writersShown: writersShown,
          isGrand: isGrand,
          qCount: qCount,
          closeClock: DailyWarSchedule.formatClock(
            DailyWarSchedule.liveEndsAt(warDate, questionCount: qCount),
          ),
        );
      case DailyWarPhase.lobby:
        return _LobbyOpen(
          topics: topics,
          untilStart: untilStart,
          lobbyShown: lobbyShown,
          isGrand: isGrand,
          qCount: qCount,
        );
      case DailyWarPhase.countdown:
      case DailyWarPhase.preAnnounce:
      case DailyWarPhase.morning:
        return _PrepareCompact(
          topics: topics,
          topicsLoadFailed: topicsLoadFailed,
          topicsLoading: topicsLoading,
          untilStart: untilStart,
          isGrand: isGrand,
          coverage: coverage,
        );
    }
  }
}

// ─── Shared chrome ───────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.left, this.right, this.pulse = false});

  final String left;
  final String? right;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (pulse) ...[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: DwColors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            left,
            style: DwText.eyebrow(color: DwColors.onDarkMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (right != null) ...[
          const SizedBox(width: 8),
          Text(right!, style: DwText.stamp()),
        ],
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, this.filled = true});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: filled ? DwColors.crimson : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: DwColors.borderOnDark),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: DwText.cta(
          color: filled ? DwColors.onDark : DwColors.onDarkMuted,
        ),
      ),
    );
  }
}

class _CountCallout extends StatelessWidget {
  const _CountCallout({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(count, style: DwText.heroNumber()),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: DwText.body()),
          ),
        ),
      ],
    );
  }
}

// ─── Compact prepare (morning + countdown) — mock 3a ─────────────────────────

class _PrepareCompact extends StatelessWidget {
  const _PrepareCompact({
    required this.topics,
    required this.topicsLoadFailed,
    required this.topicsLoading,
    required this.untilStart,
    required this.isGrand,
    required this.coverage,
  });

  final List<DailyWarTopicRef> topics;
  final bool topicsLoadFailed;
  final bool topicsLoading;
  final Duration untilStart;
  final bool isGrand;
  final ({int covered, int tonightAdds, int total}) coverage;

  @override
  Widget build(BuildContext context) {
    final topicsLine = DailyWarCopy.compactTopics(
      topics,
      loadFailed: topicsLoadFailed,
      isLoading: topicsLoading,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: isGrand
              ? '${DailyWarCopy.grandEventNameCaps} · SATURDAY'
              : DailyWarCopy.dailyEventNameCaps,
          right: '9:00 PM',
          pulse: true,
        ),
        const SizedBox(height: 8),
        Text(
          DailyWarSchedule.formatCountdown(untilStart),
          style: DwText.dm(
            size: 32,
            weight: FontWeight.w700,
            color: DwColors.onDark,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          topicsLine,
          style: DwText.dm(
            size: 15,
            weight: FontWeight.w600,
            color: DwColors.onDark,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (topics.length > 2) ...[
          const SizedBox(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(
              showDailyWarTopicsSheet(context: context, topics: topics),
            ),
            child: Text(
              '+ ${topics.length - 2} more · See all →',
              style: DwText.dm(
                size: 13,
                weight: FontWeight.w700,
                color: DwColors.crimsonBright,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _CoverageMeter(
          covered: coverage.covered,
          total: coverage.total,
          tonightAdds: coverage.tonightAdds,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(
            showDailyWarExplainerSheet(
              context: context,
              topics: topics,
              isGrand: isGrand,
            ),
          ),
          child: _PrimaryCta(label: 'Revise', filled: true),
        ),
      ],
    );
  }
}

class _CoverageMeter extends StatelessWidget {
  const _CoverageMeter({
    required this.covered,
    required this.total,
    required this.tonightAdds,
  });

  final int covered;
  final int total;
  final int tonightAdds;

  @override
  Widget build(BuildContext context) {
    final t = total <= 0 ? 1 : total;
    final progress = (covered / t).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$covered of $total topics covered',
                style: DwText.dm(
                  size: 12,
                  weight: FontWeight.w600,
                  color: DwColors.onDarkMuted,
                ),
              ),
            ),
            if (tonightAdds > 0)
              Text(
                'tonight adds $tonightAdds',
                style: DwText.dm(
                  size: 12,
                  weight: FontWeight.w600,
                  color: DwColors.gold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: DwColors.onDark.withValues(alpha: 0.08),
            color: DwColors.teal,
          ),
        ),
      ],
    );
  }
}

// ─── H3 Lobby ────────────────────────────────────────────────────────────────

class _LobbyOpen extends StatelessWidget {
  const _LobbyOpen({
    required this.topics,
    required this.untilStart,
    required this.lobbyShown,
    required this.isGrand,
    required this.qCount,
  });

  final List<DailyWarTopicRef> topics;
  final Duration untilStart;
  final String? lobbyShown;
  final bool isGrand;
  final int qCount;

  @override
  Widget build(BuildContext context) {
    final startsIn = DailyWarSchedule.formatCountdown(untilStart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: 'LOBBY OPEN',
          right: 'STARTS 9:00 PM IST',
          pulse: true,
        ),
        const SizedBox(height: 14),
        if (lobbyShown != null)
          _CountCallout(count: lobbyShown!, label: 'aspirants in the lobby')
        else
          Text('The lobby is filling up', style: DwText.topicCompact()),
        const SizedBox(height: 10),
        Text(
          DailyWarCopy.compactTopics(topics),
          style: DwText.body(color: DwColors.onDark),
        ),
        const SizedBox(height: 8),
        Text(
          DailyWarCopy.rulesLineLobby(questionCount: qCount, isGrand: isGrand),
          style: DwText.meta(),
        ),
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Enter lobby'),
        const SizedBox(height: 8),
        Text(
          'WAR STARTS IN '
          '${startsIn.length > 5 ? startsIn.substring(3) : startsIn}',
          style: DwText.stamp(color: DwColors.crimsonBright),
        ),
      ],
    );
  }
}

// ─── H4a Live joinable ───────────────────────────────────────────────────────

class _LiveJoinable extends StatelessWidget {
  const _LiveJoinable({
    required this.topics,
    required this.untilLateClose,
    required this.writersShown,
    required this.isGrand,
    required this.qCount,
    required this.closeClock,
  });

  final List<DailyWarTopicRef> topics;
  final Duration untilLateClose;
  final String? writersShown;
  final bool isGrand;
  final int qCount;
  final String closeClock;

  @override
  Widget build(BuildContext context) {
    final entry = DailyWarSchedule.formatCountdown(untilLateClose);
    final entryShort = entry.length > 5 ? entry.substring(3) : entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: 'WAR IS LIVE',
          right: 'STARTED 9:00 PM IST',
          pulse: true,
        ),
        const SizedBox(height: 12),
        Text('You can still join until 9:10', style: DwText.topicCompact()),
        const SizedBox(height: 6),
        Text(
          'Your timer starts on entry — the $closeClock close does not move.',
          style: DwText.body(),
        ),
        if (writersShown != null) ...[
          const SizedBox(height: 12),
          _CountCallout(count: writersShown!, label: 'writing right now'),
        ],
        const SizedBox(height: 8),
        Text(DailyWarCopy.compactTopics(topics), style: DwText.meta()),
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Join now'),
        const SizedBox(height: 8),
        Text(
          'ENTRY CLOSES IN $entryShort',
          style: DwText.stamp(color: DwColors.crimsonBright),
        ),
      ],
    );
  }
}

// ─── H4b Live locked ─────────────────────────────────────────────────────────

class _LiveLocked extends StatelessWidget {
  const _LiveLocked({
    required this.snap,
    required this.topics,
    required this.writersShown,
    required this.isGrand,
  });

  final DailyWarHomeSnapshot snap;
  final List<DailyWarTopicRef> topics;
  final String? writersShown;
  final bool isGrand;

  @override
  Widget build(BuildContext context) {
    final sub = snap.submission;
    final submitted = sub != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: submitted ? 'YOU\'RE IN' : 'IN PROGRESS',
          right: 'ENTRY CLOSED 9:10 PM',
          pulse: true,
        ),
        const SizedBox(height: 12),
        Text(
          submitted
              ? (sub.hasOfficialRank
                    ? 'Your AIR ${sub.air} is ready'
                    : 'Your attempt is in · AIR at 9:40 PM IST')
              : 'Tonight\'s ${DailyWarCopy.eventName(isGrand: isGrand)} is live',
          style: DwText.topicCompact(),
        ),
        const SizedBox(height: 6),
        Text(
          submitted ? DailyWarCopy.compactTopics(topics) : 'Late join closed.',
          style: DwText.body(),
        ),
        if (!submitted && writersShown != null) ...[
          const SizedBox(height: 12),
          Text(
            '$writersShown aspirants · ${DailyWarCopy.compactTopics(topics)}',
            style: DwText.meta(),
          ),
        ] else if (!submitted) ...[
          const SizedBox(height: 10),
          Text(DailyWarCopy.compactTopics(topics), style: DwText.meta()),
        ],
        const SizedBox(height: 14),
        _PrimaryCta(
          label: submitted
              ? (sub.hasOfficialRank
                    ? 'See your AIR ${sub.air}'
                    : 'Open your attempt')
              : 'Today\'s war is live',
          filled: !submitted || sub.hasOfficialRank,
        ),
      ],
    );
  }
}

class _ResultsPending extends StatelessWidget {
  const _ResultsPending({required this.snap, required this.topics});

  final DailyWarHomeSnapshot snap;
  final List<DailyWarTopicRef> topics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(left: 'RESULTS', right: 'AIR AT 9:40 PM'),
        const SizedBox(height: 12),
        Text(
          snap.submission != null
              ? 'Your score is in · we\'ll notify you when AIR is ready'
              : 'Tonight\'s battle is over · AIR at 9:40 PM',
          style: DwText.topicCompact(),
        ),
        const SizedBox(height: 8),
        Text(DailyWarCopy.compactTopics(topics), style: DwText.meta()),
      ],
    );
  }
}

// ─── H5 Result played ────────────────────────────────────────────────────────

class _ResultPlayed extends StatelessWidget {
  const _ResultPlayed({
    required this.snap,
    required this.warDate,
    required this.writersShown,
  });

  final DailyWarHomeSnapshot snap;
  final DateTime warDate;
  final String? writersShown;

  @override
  Widget build(BuildContext context) {
    final sub = snap.submission!;
    final dateLabel = DateFormat('d MMM').format(warDate).toUpperCase();
    final ofN = writersShown ?? '—';
    final next = snap.doc?.nextTopics ?? const <DailyWarTopicRef>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(left: 'TONIGHT\'S RESULT · $dateLabel'),
        const SizedBox(height: 12),
        Text('ALL-INDIA RANK', style: DwText.meta()),
        const SizedBox(height: 2),
        Text('${sub.air}', style: DwText.heroNumber()),
        Text('of $ofN', style: DwText.body(color: DwColors.onDarkMuted)),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatChip(
              label: 'PERCENTILE',
              value: sub.percentile?.toStringAsFixed(1) ?? '—',
            ),
            const SizedBox(width: 16),
            _StatChip(
              label: 'SCORE',
              value:
                  '${sub.score.toStringAsFixed(2)}/${snap.doc?.questionCount ?? 15}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Full results & review'),
        if (next.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Tomorrow · ${DailyWarCopy.compactTopics(next)}',
            style: DwText.meta(),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DwText.stamp()),
        Text(value, style: DwText.dm(size: 18, weight: FontWeight.w700)),
      ],
    );
  }
}

// ─── H6 Result sat out ───────────────────────────────────────────────────────

class _ResultSatOut extends StatelessWidget {
  const _ResultSatOut({required this.snap, required this.writersShown});

  final DailyWarHomeSnapshot snap;
  final String? writersShown;

  @override
  Widget build(BuildContext context) {
    final next = snap.doc?.nextTopics ?? const <DailyWarTopicRef>[];
    final practiced = snap.submission?.mode == 'unranked';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(left: 'TONIGHT\'S BATTLE IS OVER'),
        const SizedBox(height: 12),
        if (writersShown != null)
          Text(
            '$writersShown aspirants wrote it',
            style: DwText.body(color: DwColors.onDark),
          ),
        const SizedBox(height: 10),
        Text(
          practiced
              ? 'You practiced unranked · ${snap.submission!.score.toStringAsFixed(2)}'
              : 'You sat this one out',
          style: DwText.topicCompact(),
        ),
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'See tonight\'s paper', filled: false),
        const SizedBox(height: 8),
        const _PrimaryCta(label: 'Unranked attempt'),
        if (next.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Tomorrow · 9:00 PM IST', style: DwText.meta()),
          Text(
            DailyWarCopy.compactTopics(next),
            style: DwText.body(color: DwColors.onDark),
          ),
        ],
      ],
    );
  }
}
