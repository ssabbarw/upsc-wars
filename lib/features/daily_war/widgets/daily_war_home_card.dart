import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../daily_war_constants.dart';
import '../data/daily_war_cloud_service.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';

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
    final yesterday = ref.watch(dailyWarYesterdaySnapshotProvider);
    final liveCounts =
        ref.watch(dailyWarLiveCountsProvider).asData?.value ??
            const DailyWarLiveCounts.empty();
    final countEnabled =
        ref.watch(dailyWarLobbyCountRemoteEnabledProvider).asData?.value ??
            true;
    final minVisible =
        ref.watch(dailyWarMinVisibleLobbyCountRemoteProvider).asData?.value ??
            DailyWarSchedule.minVisibleParticipantCount;

    // Count this device in the lobby once per war day (idempotent server-side).
    final joinedLobbyDate = useRef<String?>(null);
    useEffect(() {
      final phase = snap.phase;
      if (phase != DailyWarPhase.lobby &&
          phase != DailyWarPhase.liveJoinable) {
        return null;
      }
      if (joinedLobbyDate.value == snap.dateId) return null;
      joinedLobbyDate.value = snap.dateId;
      unawaited(
        const DailyWarCloudService().joinLobby(dateId: snap.dateId),
      );
      return null;
    }, [snap.dateId, snap.phase]);

    final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
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

    final doc = snap.doc;
    final isGrand = doc?.isGrand == true || DailyWarSchedule.isGrandWarDay(warDate);
    final qCount = doc?.questionCount ??
        DailyWarSchedule.questionCountForDate(warDate);
    final topics = doc?.topics ?? const <DailyWarTopicRef>[];

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
    final lastNightShown = DailyWarCopy.formatVisibleCount(
      raw: yesterday.doc?.participantCount,
      enabled: countEnabled,
      minVisible: minVisible,
    );

    final showMissedStrip = yesterday.shouldShowMissedStrip &&
        snap.phase != DailyWarPhase.lobby &&
        snap.phase != DailyWarPhase.liveJoinable &&
        snap.phase != DailyWarPhase.liveLocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(dailyWarLobbyRoute()),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  color: DwColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DwColors.borderOnDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: _HeroBody(
                    snap: snap,
                    isGrand: isGrand,
                    qCount: qCount,
                    topics: topics,
                    untilStart: untilStart,
                    untilLateClose: untilLateClose,
                    lobbyShown: lobbyShown,
                    writersShown: writersShown,
                    lastNightShown: lastNightShown,
                    warDate: warDate,
                  ),
                ),
              ),
            ),
          ),
          if (showMissedStrip) ...[
            const SizedBox(height: 8),
            _MissedYesterdayStrip(yesterday: yesterday),
          ],
        ],
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
    required this.untilStart,
    required this.untilLateClose,
    required this.lobbyShown,
    required this.writersShown,
    required this.lastNightShown,
    required this.warDate,
  });

  final DailyWarHomeSnapshot snap;
  final bool isGrand;
  final int qCount;
  final List<DailyWarTopicRef> topics;
  final Duration untilStart;
  final Duration untilLateClose;
  final String? lobbyShown;
  final String? writersShown;
  final String? lastNightShown;
  final DateTime warDate;

  @override
  Widget build(BuildContext context) {
    switch (snap.phase) {
      case DailyWarPhase.resultsReady:
        if (snap.submission?.hasOfficialRank == true) {
          return _ResultPlayed(
            snap: snap,
            warDate: warDate,
            writersShown: writersShown,
          );
        }
        return _ResultSatOut(
          snap: snap,
          writersShown: writersShown,
        );
      case DailyWarPhase.resultsPending:
        return _ResultsPending(snap: snap, topics: topics);
      case DailyWarPhase.liveLocked:
        return _LiveLocked(
          topics: topics,
          writersShown: writersShown,
          isGrand: isGrand,
          qCount: qCount,
        );
      case DailyWarPhase.liveJoinable:
        return _LiveJoinable(
          topics: topics,
          untilLateClose: untilLateClose,
          writersShown: writersShown,
          isGrand: isGrand,
          qCount: qCount,
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
        return _Countdown(
          topics: topics,
          untilStart: untilStart,
          lastNightShown: lastNightShown,
          isGrand: isGrand,
          qCount: qCount,
        );
      case DailyWarPhase.preAnnounce:
      case DailyWarPhase.morning:
        if (isGrand) {
          return _GrandMorning(topics: topics, qCount: qCount);
        }
        return _Morning(
          topics: topics,
          isGrand: isGrand,
          qCount: qCount,
        );
    }
  }
}

// ─── Shared chrome ───────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.left,
    this.right,
    this.pulse = false,
  });

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
              color: DwColors.crimsonBright,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(left, style: DwText.eyebrow()),
        const Spacer(),
        if (right != null)
          Text(right!, style: DwText.stamp()),
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
        border: filled
            ? null
            : Border.all(color: DwColors.borderOnDark),
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

class _TopicBlock extends StatelessWidget {
  const _TopicBlock({
    required this.topics,
    this.compact = false,
    this.eyebrow = 'Tonight\'s paper',
  });

  final List<DailyWarTopicRef> topics;
  final bool compact;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Text('Tonight\'s topics loading…', style: DwText.topicCompact());
    }
    final subjects = DailyWarCopy.subjectsLine(topics).toUpperCase();
    final multiSubject =
        topics.map((t) => t.subjectSlug).toSet().length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          multiSubject ? '$eyebrow · two subjects' : eyebrow,
          style: DwText.meta(),
        ),
        const SizedBox(height: 6),
        Text(subjects, style: DwText.subject(color: DwColors.crimsonBright)),
        const SizedBox(height: 4),
        for (final t in topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              t.topic,
              style: compact ? DwText.topicCompact() : DwText.topic(),
            ),
          ),
      ],
    );
  }
}

class _CountCallout extends StatelessWidget {
  const _CountCallout({
    required this.count,
    required this.label,
  });

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

// ─── H1 Morning ──────────────────────────────────────────────────────────────

class _Morning extends StatelessWidget {
  const _Morning({
    required this.topics,
    required this.isGrand,
    required this.qCount,
  });

  final List<DailyWarTopicRef> topics;
  final bool isGrand;
  final int qCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: isGrand ? 'GRAND WAR' : 'DAILY WAR',
          right: 'TONIGHT 9:00 PM IST',
        ),
        const SizedBox(height: 14),
        _TopicBlock(topics: topics),
        const SizedBox(height: 12),
        Text(
          DailyWarCopy.rulesLine(questionCount: qCount, isGrand: isGrand),
          style: DwText.meta(color: DwColors.onDarkMuted),
        ),
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Prepare these topics', filled: false),
      ],
    );
  }
}

class _GrandMorning extends StatelessWidget {
  const _GrandMorning({required this.topics, required this.qCount});

  final List<DailyWarTopicRef> topics;
  final int qCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusRow(
          left: 'GRAND WAR · SUNDAY',
          right: 'TONIGHT 9:00 PM IST',
        ),
        const SizedBox(height: 14),
        Text(
          'This week\'s topics, revised in one paper',
          style: DwText.body(),
        ),
        const SizedBox(height: 10),
        _TopicBlock(topics: topics, compact: true, eyebrow: 'Tonight\'s paper'),
        const SizedBox(height: 12),
        Text(
          DailyWarCopy.rulesLine(questionCount: qCount, isGrand: true),
          style: DwText.meta(color: DwColors.onDarkMuted),
        ),
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Prepare for Grand War', filled: false),
      ],
    );
  }
}

// ─── H2 Countdown ────────────────────────────────────────────────────────────

class _Countdown extends StatelessWidget {
  const _Countdown({
    required this.topics,
    required this.untilStart,
    required this.lastNightShown,
    required this.isGrand,
    required this.qCount,
  });

  final List<DailyWarTopicRef> topics;
  final Duration untilStart;
  final String? lastNightShown;
  final bool isGrand;
  final int qCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: isGrand ? 'GRAND WAR' : 'DAILY WAR',
          right: '9:00 PM IST',
        ),
        const SizedBox(height: 12),
        Text('WAR BEGINS IN', style: DwText.meta()),
        const SizedBox(height: 4),
        Text(
          DailyWarSchedule.formatCountdown(untilStart),
          style: DwText.heroNumber(color: DwColors.crimsonBright),
        ),
        const SizedBox(height: 10),
        Text(
          DailyWarCopy.compactTopics(topics),
          style: DwText.body(color: DwColors.onDark),
        ),
        const SizedBox(height: 8),
        Text(
          DailyWarCopy.rulesLine(questionCount: qCount, isGrand: isGrand),
          style: DwText.meta(),
        ),
        if (lastNightShown != null) ...[
          const SizedBox(height: 12),
          _CountCallout(
            count: lastNightShown!,
            label: 'aspirants wrote last night\'s paper',
          ),
        ],
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Revise the topic', filled: false),
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
    final doors = DailyWarSchedule.formatCountdown(untilStart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusRow(
          left: 'LOBBY OPEN',
          right: 'STARTS 9:00 PM IST',
          pulse: true,
        ),
        const SizedBox(height: 14),
        if (lobbyShown != null)
          _CountCallout(
            count: lobbyShown!,
            label: 'aspirants in the lobby',
          )
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
          'DOORS CLOSE IN ${doors.length > 5 ? doors.substring(3) : doors}',
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
  });

  final List<DailyWarTopicRef> topics;
  final Duration untilLateClose;
  final String? writersShown;
  final bool isGrand;
  final int qCount;

  @override
  Widget build(BuildContext context) {
    final entry = DailyWarSchedule.formatCountdown(untilLateClose);
    final entryShort = entry.length > 5 ? entry.substring(3) : entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusRow(
          left: 'WAR IS LIVE',
          right: 'STARTED 9:00 PM IST',
          pulse: true,
        ),
        const SizedBox(height: 12),
        Text('You can still join until 9:10', style: DwText.topicCompact()),
        const SizedBox(height: 6),
        Text(
          'Your timer starts on entry — the 9:20 close does not move.',
          style: DwText.body(),
        ),
        if (writersShown != null) ...[
          const SizedBox(height: 12),
          _CountCallout(
            count: writersShown!,
            label: 'writing right now',
          ),
        ],
        const SizedBox(height: 8),
        Text(
          DailyWarCopy.compactTopics(topics),
          style: DwText.meta(),
        ),
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
    required this.topics,
    required this.writersShown,
    required this.isGrand,
    required this.qCount,
  });

  final List<DailyWarTopicRef> topics;
  final String? writersShown;
  final bool isGrand;
  final int qCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusRow(
          left: 'IN PROGRESS',
          right: 'ENTRY CLOSED 9:10 PM',
          pulse: true,
        ),
        const SizedBox(height: 12),
        Text('Tonight\'s paper is being written', style: DwText.topicCompact()),
        const SizedBox(height: 6),
        Text(
          'Results and All-India Rank at 9:25 PM IST.',
          style: DwText.body(),
        ),
        if (writersShown != null) ...[
          const SizedBox(height: 12),
          Text(
            '$writersShown aspirants · ${DailyWarCopy.compactTopics(topics)}',
            style: DwText.meta(),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Text(
            DailyWarCopy.compactTopics(topics),
            style: DwText.meta(),
          ),
        ],
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Read the topic notes', filled: false),
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
        const _StatusRow(left: 'RESULTS', right: 'CALCULATING…'),
        const SizedBox(height: 12),
        Text(
          snap.submission != null
              ? 'Calculating your All-India Rank…'
              : 'Tonight\'s War is over · ranks shortly',
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
        Text(
          'of $ofN',
          style: DwText.body(color: DwColors.onDarkMuted),
        ),
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
            'Tomorrow\'s War · ${DailyWarCopy.compactTopics(next)}',
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
  const _ResultSatOut({
    required this.snap,
    required this.writersShown,
  });

  final DailyWarHomeSnapshot snap;
  final String? writersShown;

  @override
  Widget build(BuildContext context) {
    final next = snap.doc?.nextTopics ?? const <DailyWarTopicRef>[];
    final practiced = snap.submission?.mode == 'unranked';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusRow(left: 'TONIGHT\'S WAR IS OVER'),
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
          Text(
            'Tomorrow\'s War · 9:00 PM IST',
            style: DwText.meta(),
          ),
          Text(
            DailyWarCopy.compactTopics(next),
            style: DwText.body(color: DwColors.onDark),
          ),
        ],
      ],
    );
  }
}

// ─── H7 Missed yesterday ─────────────────────────────────────────────────────

class _MissedYesterdayStrip extends StatelessWidget {
  const _MissedYesterdayStrip({required this.yesterday});

  final DailyWarYesterdaySnapshot yesterday;

  @override
  Widget build(BuildContext context) {
    final q = yesterday.doc?.questionCount ?? 15;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(dailyWarHistoryRoute()),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: DwColors.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1F000000)),
          ),
          child: Row(
            children: [
              Icon(Icons.history_toggle_off, size: 20, color: DwColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yesterday\'s paper is open',
                      style: DwText.dm(
                        size: 13,
                        weight: FontWeight.w700,
                        color: DwColors.ink,
                      ),
                    ),
                    Text(
                      'Attempt unranked · $q Q · see where you\'d have stood',
                      style: DwText.dm(
                        size: 11,
                        color: DwColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: DwColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
