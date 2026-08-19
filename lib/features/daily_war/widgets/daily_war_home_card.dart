import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_coverage.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/daily_war_week_summary.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_explainer_sheet.dart';
import 'daily_war_help_sheet.dart';
import 'daily_war_sunday_card.dart';
import 'daily_war_topics_sheet.dart';

/// Home hero for Daily War — three-band near-black card (design H1–H9).
class DailyWarHomeCard extends HookConsumerWidget {
  const DailyWarHomeCard({
    super.key,
    this.forceCollapsed = false,
    this.forceExpanded = false,
  });

  /// When true (e.g. activation journey), start collapsed so START HERE stays
  /// the hero. User can still expand for the session.
  final bool forceCollapsed;

  /// When true (Tonight's War is the home hero), ignore sticky collapse prefs
  /// so the card opens expanded. Session toggle still works.
  final bool forceExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(dailyWarRemoteEnabledProvider);
    return enabled.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (on) {
        if (!on) return const SizedBox.shrink();
        return _DailyWarHomeCardBody(
          forceCollapsed: forceCollapsed,
          forceExpanded: forceExpanded,
        );
      },
    );
  }
}

class _DailyWarHomeCardBody extends HookConsumerWidget {
  const _DailyWarHomeCardBody({
    this.forceCollapsed = false,
    this.forceExpanded = false,
  });

  final bool forceCollapsed;
  final bool forceExpanded;
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
    final yesterday = ref.watch(dailyWarYesterdaySnapshotProvider);
    final countEnabled =
        ref.watch(dailyWarLobbyCountRemoteEnabledProvider).asData?.value ??
        true;
    final minVisible =
        ref.watch(dailyWarMinVisibleLobbyCountRemoteProvider).asData?.value ??
        DailyWarSchedule.minVisibleParticipantCount;

    final prefs = ref.watch(prefsServiceProvider).asData?.value;
    final storedCollapse = prefs?.dailyWarHomeCollapsedOrNull;
    final isRest = snap.phase == DailyWarPhase.restDay;
    final collapseUi = ref.watch(dailyWarHomeCollapseProvider);
    final sessionCollapse = collapseUi?.dateId == snap.dateId
        ? collapseUi!.collapsed
        : null;
    // Sunday defaults collapsed; weekday uses sticky prefs. Session override
    // survives ListView scroll dispose (keepAlive provider).
    // [forceCollapsed] keeps War quiet while START HERE is on screen.
    final isCollapsed = forceExpanded
        ? (sessionCollapse ?? false)
        : sessionCollapse ??
              (forceCollapsed
                  ? true
                  : (isRest ? true : (storedCollapse ?? false)));

    void setCollapsed(bool value) {
      ref
          .read(dailyWarHomeCollapseProvider.notifier)
          .setCollapsed(dateId: snap.dateId, collapsed: value);
      // Don't let a Sunday expand stick into Mon–Sat prefs.
      if (!isRest) prefs?.dailyWarHomeCollapsed = value;
    }

    // Lobby presence is counted when the user opens the lobby screen — not from
    // home (collapsed or expanded). Avoids a callable+tx per DAU on home.

    // RTDB counts only when expanded. History also when Sunday (week summary
    // on the collapsed card).
    final liveCounts = (!isCollapsed && countEnabled)
        ? (ref.watch(dailyWarLiveCountsProvider).asData?.value ??
              const DailyWarLiveCounts.empty())
        : const DailyWarLiveCounts.empty();
    final historyBundle = (!isCollapsed || isRest)
        ? ref.watch(dailyWarHistoryBundleProvider).asData?.value
        : null;

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
    final yesterdayOpen =
        yesterday.shouldShowMissedStrip &&
        snap.phase != DailyWarPhase.lobby &&
        snap.phase != DailyWarPhase.liveJoinable &&
        snap.phase != DailyWarPhase.liveLocked &&
        snap.phase != DailyWarPhase.restDay;

    final historyWars = historyBundle?.wars ?? const <DailyWarDoc>[];
    final coverage = DailyWarCoverage.compute(
      historyWars: historyWars,
      tonightTopics: topics,
      tonightDoc: doc,
    );

    DailyWarWeekSummary? sundaySummary;
    if (isRest) {
      final restCoverage = DailyWarCoverage.compute(
        historyWars: historyWars,
        tonightTopics: const [],
      );
      sundaySummary = DailyWarWeekSummary.build(
        sundayIst: ist,
        wars: historyWars,
        submissions: historyBundle?.submissions ?? const {},
        syllabusTopicsCovered: restCoverage.covered,
      );
    }

    final eyebrow = _collapsedEyebrow(phase: snap.phase, isGrand: isGrand);
    final collapsedLine = _collapsedSubtitle(
      snap: snap,
      isGrand: isGrand,
      untilStart: untilStart,
      untilLateClose: untilLateClose,
      topics: topics,
      writersShown: writersShown,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCollapsed
              ? () => setCollapsed(false)
              : isRest
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
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: isCollapsed
                  ? (isRest && sundaySummary != null
                        ? _CollapsedSundayWeek(
                            summary: sundaySummary,
                            onExpand: () => setCollapsed(false),
                          )
                        : _CollapsedWarHeader(
                            eyebrow: eyebrow,
                            subtitle: collapsedLine,
                            pulse:
                                snap.phase == DailyWarPhase.lobby ||
                                snap.phase == DailyWarPhase.liveJoinable ||
                                snap.phase == DailyWarPhase.liveLocked ||
                                snap.phase == DailyWarPhase.morning ||
                                snap.phase == DailyWarPhase.countdown ||
                                snap.phase == DailyWarPhase.preAnnounce,
                            onExpand: () => setCollapsed(false),
                          ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isRest)
                          DailyWarSundayCard(
                            onCollapse: () => setCollapsed(true),
                          )
                        else ...[
                          _HeroBody(
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
                            onCollapse: () => setCollapsed(true),
                          ),
                          const SizedBox(height: 12),
                          _WarHistoryLink(yesterdayOpen: yesterdayOpen),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

String _collapsedEyebrow({
  required DailyWarPhase phase,
  required bool isGrand,
}) {
  switch (phase) {
    case DailyWarPhase.restDay:
      return 'SUNDAY · REST';
    case DailyWarPhase.lobby:
      return 'LOBBY OPEN';
    case DailyWarPhase.liveJoinable:
      return 'WAR IS LIVE';
    case DailyWarPhase.liveLocked:
      return 'IN PROGRESS';
    case DailyWarPhase.resultsPending:
      return 'RESULTS';
    case DailyWarPhase.resultsReady:
      return 'RESULTS';
    case DailyWarPhase.countdown:
    case DailyWarPhase.preAnnounce:
    case DailyWarPhase.morning:
      return isGrand ? 'GRAND WAR · SATURDAY' : 'DAILY WAR';
  }
}

String _collapsedSubtitle({
  required DailyWarHomeSnapshot snap,
  required bool isGrand,
  required Duration untilStart,
  required Duration untilLateClose,
  required List<DailyWarTopicRef> topics,
  required String? writersShown,
}) {
  switch (snap.phase) {
    case DailyWarPhase.restDay:
      return 'Week summary';
    case DailyWarPhase.lobby:
      return 'Starts in ${DailyWarSchedule.formatCountdown(untilStart)}';
    case DailyWarPhase.liveJoinable:
      return 'Join until ${DailyWarSchedule.formatCountdown(untilLateClose)}';
    case DailyWarPhase.liveLocked:
      return writersShown != null
          ? '$writersShown writing · AIR at 9:40'
          : 'Paper closed · AIR at 9:40';
    case DailyWarPhase.resultsPending:
      return snap.submission != null
          ? 'Score submitted · AIR at 9:40'
          : 'AIR at 9:40';
    case DailyWarPhase.resultsReady:
      final sub = snap.submission;
      if (sub?.hasOfficialRank == true) {
        final air = sub!.air;
        return air != null ? 'AIR #$air' : 'Results ready';
      }
      return 'You sat out';
    case DailyWarPhase.countdown:
    case DailyWarPhase.preAnnounce:
    case DailyWarPhase.morning:
      final cd = DailyWarSchedule.formatCountdown(untilStart);
      final tip = topics.isEmpty
          ? (isGrand ? 'Week revision' : 'Two topics a night')
          : topics.first.topic;
      return '$cd · $tip';
  }
}

String _sundayWeekHeadline(DailyWarWeekSummary s) {
  if (s.attemptedNone) {
    final n = s.missedTopics.length;
    return n > 0 ? '$n topics waited' : 'A quiet front';
  }
  if (s.attemptedAll) {
    return s.playedGrand ? 'Full week · Grand included' : 'Clean sweep';
  }
  if (s.bestAir != null) {
    return 'Best AIR #${s.bestAir}';
  }
  return '${s.attemptedNights} nights fought';
}

String _sundayWeekMeta(DailyWarWeekSummary s) {
  if (s.attemptedNone) {
    return '0/${s.warNights} nights · Monday opens fresh';
  }
  final parts = <String>['${s.attemptedNights}/${s.warNights} nights'];
  if (s.accuracyPct != null) {
    parts.add('${s.accuracyPct!.round()}%');
  }
  if (s.playedGrand) {
    parts.add('Grand ✓');
  } else if (s.attemptedPartial) {
    parts.add('${s.missedTopics.length} topics open');
  }
  if (s.peakStreakDays > 0) {
    parts.add('${s.peakStreakDays}-night streak');
  }
  return parts.join(' · ');
}

/// Collapsed Sunday — week orbit + one creative rollup (no “rest / tap” copy).
class _CollapsedSundayWeek extends StatelessWidget {
  const _CollapsedSundayWeek({required this.summary, required this.onExpand});

  final DailyWarWeekSummary summary;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final warDays = summary.days.where((d) => !d.isRest).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'THIS WEEK IN DAILY WARS',
                style: DwText.eyebrow(color: const Color(0x99C5CDFF)),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(showDailyWarHelpSheet(context)),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: DwColors.onDarkMuted,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExpand,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 0, 4),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: DwColors.onDarkMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < warDays.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: DwColors.onDark.withValues(alpha: 0.08),
                  ),
                ),
              _CollapsedDayDot(day: warDays[i]),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _sundayWeekHeadline(summary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DwText.dm(
            size: 16,
            weight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _sundayWeekMeta(summary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DwText.dm(
            size: 12,
            weight: FontWeight.w500,
            color: DwColors.onDarkMuted,
          ),
        ),
      ],
    );
  }
}

class _CollapsedDayDot extends StatelessWidget {
  const _CollapsedDayDot({required this.day});

  final DailyWarWeekDayCell day;

  @override
  Widget build(BuildContext context) {
    final attempted = day.attempted;
    final Color ring;
    final Color fill;
    final Color label;
    if (attempted) {
      ring = day.isGrand
          ? DwColors.gold.withValues(alpha: 0.75)
          : DwColors.teal.withValues(alpha: 0.75);
      fill = day.isGrand
          ? DwColors.gold.withValues(alpha: 0.22)
          : DwColors.teal.withValues(alpha: 0.22);
      label = day.isGrand ? DwColors.gold : DwColors.teal;
    } else {
      ring = DwColors.onDark.withValues(alpha: 0.16);
      fill = Colors.transparent;
      label = DwColors.onDarkFaint;
    }

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: ring, width: 1.3),
          ),
          alignment: Alignment.center,
          child: Text(
            day.label,
            style: DwText.dm(size: 10, weight: FontWeight.w800, color: label),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          attempted ? (day.scoreLabel ?? '✓') : '·',
          style: DwText.dm(
            size: 9,
            weight: FontWeight.w600,
            color: attempted ? DwColors.onDarkMuted : DwColors.onDarkFaint,
          ),
        ),
      ],
    );
  }
}

class _CollapsedWarHeader extends StatelessWidget {
  const _CollapsedWarHeader({
    required this.eyebrow,
    required this.subtitle,
    required this.onExpand,
    this.pulse = false,
  });

  final String eyebrow;
  final String subtitle;
  final VoidCallback onExpand;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pulse) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: DwColors.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: DwText.eyebrow(color: DwColors.onDarkMuted)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DwText.dm(
                  size: 14,
                  weight: FontWeight.w600,
                  color: DwColors.onDark,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(showDailyWarHelpSheet(context)),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.help_outline_rounded,
              size: 16,
              color: DwColors.onDarkMuted,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onExpand,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 0, 4),
            child: Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: DwColors.onDarkMuted,
            ),
          ),
        ),
      ],
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
    required this.onCollapse,
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
  final VoidCallback onCollapse;

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
            onCollapse: onCollapse,
          );
        }
        return _ResultSatOut(
          snap: snap,
          writersShown: writersShown,
          onCollapse: onCollapse,
        );
      case DailyWarPhase.resultsPending:
        return _ResultsPending(
          snap: snap,
          topics: topics,
          onCollapse: onCollapse,
        );
      case DailyWarPhase.liveLocked:
        return _LiveLocked(
          topics: topics,
          writersShown: writersShown,
          isGrand: isGrand,
          qCount: qCount,
          onCollapse: onCollapse,
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
          onCollapse: onCollapse,
        );
      case DailyWarPhase.lobby:
        return _LobbyOpen(
          topics: topics,
          untilStart: untilStart,
          lobbyShown: lobbyShown,
          isGrand: isGrand,
          qCount: qCount,
          onCollapse: onCollapse,
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
          qCount: qCount,
          coverage: coverage,
          onCollapse: onCollapse,
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
    this.showHelp = false,
    this.onHelp,
    this.onCollapse,
  });

  final String left;
  final String? right;
  final bool pulse;
  final bool showHelp;
  final VoidCallback? onHelp;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
        if (showHelp) ...[
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (onHelp != null) {
                onHelp!();
                return;
              }
              unawaited(showDailyWarHelpSheet(context));
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: DwColors.onDarkMuted,
              ),
            ),
          ),
        ],
        if (onCollapse != null) ...[
          const SizedBox(width: 2),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 0, 4),
            child: Icon(
              Icons.expand_less_rounded,
              size: 20,
              color: DwColors.onDarkMuted,
            ),
          ),
        ],
      ],
    );
    if (onCollapse == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCollapse,
      child: row,
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
    required this.qCount,
    required this.coverage,
    required this.onCollapse,
  });

  final List<DailyWarTopicRef> topics;
  final bool topicsLoadFailed;
  final bool topicsLoading;
  final Duration untilStart;
  final bool isGrand;
  final int qCount;
  final ({int covered, int tonightAdds, int total}) coverage;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final mins = DailyWarSchedule.liveWindowMinutesFor(qCount);
    final topicCount = topics.isEmpty ? (isGrand ? null : 2) : topics.length;
    final topicMeta = topicCount == null
        ? (isGrand ? 'Week revision' : '2 new topics')
        : isGrand
        ? '$topicCount topics · week revision'
        : '$topicCount new topics';
    final topicsLine = DailyWarCopy.compactTopics(
      topics,
      loadFailed: topicsLoadFailed,
      isLoading: topicsLoading,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: isGrand ? 'GRAND WAR · SATURDAY' : 'DAILY WAR',
          right: '9:00 PM',
          pulse: true,
          showHelp: true,
          onHelp: () => unawaited(
            showDailyWarExplainerSheet(
              context: context,
              topics: topics,
              isGrand: isGrand,
            ),
          ),
          onCollapse: onCollapse,
        ),
        const SizedBox(height: 12),
        Text(
          DailyWarSchedule.formatCountdown(untilStart),
          style: DwText.dm(
            size: 36,
            weight: FontWeight.w700,
            color: DwColors.onDark,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$topicMeta · $qCount Q · $mins min',
          style: DwText.meta(color: DwColors.onDarkMuted),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 12),
        _CoverageMeter(
          covered: coverage.covered,
          total: coverage.total,
          tonightAdds: coverage.tonightAdds,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(
            showDailyWarExplainerSheet(
              context: context,
              topics: topics,
              isGrand: isGrand,
            ),
          ),
          child: _PrimaryCta(
            label: isGrand ? 'How Grand War works' : 'What is Daily War?',
            filled: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 14,
              color: DwColors.onDarkFaint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'We ping you when the paper opens.',
                style: DwText.dm(
                  size: 11,
                  weight: FontWeight.w500,
                  color: DwColors.onDarkFaint,
                ),
              ),
            ),
          ],
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
    required this.onCollapse,
  });

  final List<DailyWarTopicRef> topics;
  final Duration untilStart;
  final String? lobbyShown;
  final bool isGrand;
  final int qCount;
  final VoidCallback onCollapse;

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
          onCollapse: onCollapse,
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
    required this.onCollapse,
  });

  final List<DailyWarTopicRef> topics;
  final Duration untilLateClose;
  final String? writersShown;
  final bool isGrand;
  final int qCount;
  final String closeClock;
  final VoidCallback onCollapse;

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
          onCollapse: onCollapse,
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
    required this.topics,
    required this.writersShown,
    required this.isGrand,
    required this.qCount,
    required this.onCollapse,
  });

  final List<DailyWarTopicRef> topics;
  final String? writersShown;
  final bool isGrand;
  final int qCount;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: 'IN PROGRESS',
          right: 'ENTRY CLOSED 9:10 PM',
          pulse: true,
          onCollapse: onCollapse,
        ),
        const SizedBox(height: 12),
        Text('Tonight\'s paper is being written', style: DwText.topicCompact()),
        const SizedBox(height: 6),
        Text(
          'Score on submission · All-India Rank at 9:40 PM IST.',
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
          Text(DailyWarCopy.compactTopics(topics), style: DwText.meta()),
        ],
        const SizedBox(height: 14),
        const _PrimaryCta(label: 'Read the topic notes', filled: false),
      ],
    );
  }
}

class _ResultsPending extends StatelessWidget {
  const _ResultsPending({
    required this.snap,
    required this.topics,
    required this.onCollapse,
  });

  final DailyWarHomeSnapshot snap;
  final List<DailyWarTopicRef> topics;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: 'RESULTS',
          right: 'AIR AT 9:40 PM',
          onCollapse: onCollapse,
        ),
        const SizedBox(height: 12),
        Text(
          snap.submission != null
              ? 'Your score is in · we\'ll notify you when AIR is ready'
              : 'Tonight\'s War is over · AIR at 9:40 PM',
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
    required this.onCollapse,
  });

  final DailyWarHomeSnapshot snap;
  final DateTime warDate;
  final String? writersShown;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final sub = snap.submission!;
    final dateLabel = DateFormat('d MMM').format(warDate).toUpperCase();
    final ofN = writersShown ?? '—';
    final next = snap.doc?.nextTopics ?? const <DailyWarTopicRef>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          left: 'TONIGHT\'S RESULT · $dateLabel',
          onCollapse: onCollapse,
        ),
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
    required this.onCollapse,
  });

  final DailyWarHomeSnapshot snap;
  final String? writersShown;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final next = snap.doc?.nextTopics ?? const <DailyWarTopicRef>[];
    final practiced = snap.submission?.mode == 'unranked';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(left: 'TONIGHT\'S WAR IS OVER', onCollapse: onCollapse),
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
          Text('Tomorrow\'s War · 9:00 PM IST', style: DwText.meta()),
          Text(
            DailyWarCopy.compactTopics(next),
            style: DwText.body(color: DwColors.onDark),
          ),
        ],
      ],
    );
  }
}

// ─── History link (inside War card) ──────────────────────────────────────────

class _WarHistoryLink extends StatelessWidget {
  const _WarHistoryLink({required this.yesterdayOpen});

  final bool yesterdayOpen;

  @override
  Widget build(BuildContext context) {
    final label = yesterdayOpen
        ? 'Yesterday\'s paper is open · History →'
        : 'War history →';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(dailyWarHistoryRoute()),
      child: Text(
        label,
        style: DwText.dm(
          size: 12,
          weight: FontWeight.w600,
          color: yesterdayOpen ? DwColors.crimsonBright : DwColors.onDarkMuted,
        ),
      ),
    );
  }
}
