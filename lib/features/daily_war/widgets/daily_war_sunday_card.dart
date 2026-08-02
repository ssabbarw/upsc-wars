import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_coverage.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/daily_war_week_summary.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_help_sheet.dart';
import 'daily_war_topics_sheet.dart';
import 'daily_war_week_progress_sheet.dart';

/// Sunday home hero — calm rest-day composition with week recap + Monday dock.
class DailyWarSundayCard extends ConsumerWidget {
  const DailyWarSundayCard({super.key, this.onCollapse});

  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utc = ref.watch(serverNowUtcProvider);
    final ist = DailyWarSchedule.nowIst(utc);
    final mondayId = DailyWarSchedule.formatIsoDate(
      DailyWarSchedule.nextWarDate(ist),
    );
    final saturdayId = DailyWarSchedule.formatIsoDate(
      DailyWarSchedule.previousWarDate(ist),
    );

    final bundle = ref.watch(dailyWarHistoryBundleProvider).asData?.value;
    final mondayDoc =
        ref.watch(dailyWarDocByIdProvider(mondayId)).asData?.value;
    DailyWarDoc? saturdayDoc;
    for (final w in bundle?.wars ?? const <DailyWarDoc>[]) {
      if (w.dateId == saturdayId) {
        saturdayDoc = w;
        break;
      }
    }
    saturdayDoc ??=
        ref.watch(dailyWarDocByIdProvider(saturdayId)).asData?.value;

    final mondayTopics = mondayDoc?.topics.isNotEmpty == true
        ? mondayDoc!.topics
        : (saturdayDoc?.nextTopics ?? const <DailyWarTopicRef>[]);

    final coverage = DailyWarCoverage.compute(
      historyWars: bundle?.wars ?? const [],
      tonightTopics: const [],
    );

    final summary = DailyWarWeekSummary.build(
      sundayIst: ist,
      wars: bundle?.wars ?? const [],
      submissions: bundle?.submissions ?? const {},
      syllabusTopicsCovered: coverage.covered,
    );

    final header = Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFAEB8FF).withValues(alpha: 0.35),
                const Color(0xFFAEB8FF).withValues(alpha: 0.05),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.nightlight_round,
            size: 15,
            color: Color(0xFFC5CDFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUNDAY · NO WAR TONIGHT',
                style: DwText.eyebrow(color: const Color(0x99C5CDFF)),
              ),
              const SizedBox(height: 2),
              Text(
                'Rest day · War returns Monday 9 PM',
                style: DwText.dm(
                  size: 11,
                  weight: FontWeight.w500,
                  color: DwColors.onDarkFaint,
                ),
              ),
            ],
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
        if (onCollapse != null)
          const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.expand_less_rounded,
              size: 20,
              color: DwColors.onDarkMuted,
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onCollapse != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCollapse,
            child: header,
          )
        else
          header,
        const SizedBox(height: 16),
        Text(
          _headline(summary),
          style: DwText.dm(
            size: 20,
            weight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _subhead(summary),
          style: DwText.dm(
            size: 13,
            weight: FontWeight.w500,
            color: DwColors.onDarkMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        _WeekOrbit(days: summary.days),
        const SizedBox(height: 14),
        _WeekSummaryPreview(summary: summary),
        const SizedBox(height: 16),
        _MondayDock(
          summary: summary,
          mondayTopics: mondayTopics,
        ),
      ],
    );
  }

  static String _headline(DailyWarWeekSummary s) {
    if (s.attemptedNone) {
      return 'A quiet week';
    }
    if (s.attemptedAll) {
      return 'Week ${s.weekNumber} complete';
    }
    return '${s.attemptedNights} of ${s.warNights} nights';
  }

  static String _subhead(DailyWarWeekSummary s) {
    if (s.attemptedNone) {
      final n = s.missedTopics.length;
      return n > 0
          ? '$n topics went by · nothing lost for Monday'
          : 'No War nights this week · Monday is a fresh start';
    }
    if (s.attemptedAll) {
      return 'Streak safe · revise or rest until Monday';
    }
    return '${s.topicsCovered} topics landed'
        '${s.missedTopics.isEmpty ? '' : ' · ${s.missedTopics.length} still open'}';
  }
}

/// Primary Sunday action — week stats + full progress sheet.
class _WeekSummaryPreview extends ConsumerWidget {
  const _WeekSummaryPreview({required this.summary});

  final DailyWarWeekSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateIds = [
      for (final d in summary.days)
        if (!d.isRest) DailyWarSchedule.formatIsoDate(d.date),
    ].join('|');
    final dangerCount = ref
            .watch(dailyWarWeekConfidentWrongProvider(dateIds))
            .asData
            ?.value
            .length ??
        0;
    final badgeCount = summary.badgeCounts.fold<int>(
      0,
      (sum, b) => sum + b.count,
    );
    final accuracy = summary.accuracyPct == null
        ? '—'
        : '${summary.accuracyPct!.round()}%';

    void openSummary() {
      unawaited(
        showDailyWarWeekProgressSheet(
          context: context,
          summary: summary,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: openSummary,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFA8B4FF).withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: const Color(0x33A8B4FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Stat(
                    value: '${summary.attemptedNights}/${summary.warNights}',
                    label: 'nights',
                  ),
                  _VDiv(),
                  _Stat(value: accuracy, label: 'accuracy'),
                  _VDiv(),
                  _Stat(
                    value: '$dangerCount',
                    label: 'danger',
                    emphasize: dangerCount > 0,
                  ),
                  _VDiv(),
                  _Stat(value: '$badgeCount', label: 'badges'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: openSummary,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC5CDFF),
                    foregroundColor: DwColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Full week summary',
                    style: DwText.dm(
                      size: 13,
                      weight: FontWeight.w800,
                      color: DwColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.emphasize = false,
  });

  final String value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: DwText.dm(
              size: 16,
              weight: FontWeight.w800,
              color: emphasize ? DwColors.crimsonBright : DwColors.onDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: DwText.dm(
              size: 10,
              weight: FontWeight.w600,
              color: DwColors.onDarkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: DwColors.onDark.withValues(alpha: 0.08),
    );
  }
}

/// Soft week track — filled orbs for nights fought, hollow for missed, moon for rest.
class _WeekOrbit extends StatelessWidget {
  const _WeekOrbit({required this.days});

  final List<DailyWarWeekDayCell> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18A8B4FF)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 1,
                  color: DwColors.onDark.withValues(alpha: 0.08),
                ),
              ),
            _OrbitNode(day: days[i]),
          ],
        ],
      ),
    );
  }
}

class _OrbitNode extends StatelessWidget {
  const _OrbitNode({required this.day});

  final DailyWarWeekDayCell day;

  @override
  Widget build(BuildContext context) {
    final attempted = day.attempted;
    final isRest = day.isRest;

    Color ring;
    Color fill;
    Color labelColor;
    if (isRest) {
      ring = const Color(0x55A8B4FF);
      fill = const Color(0x22A8B4FF);
      labelColor = const Color(0xFFC5CDFF);
    } else if (attempted) {
      ring = day.isGrand
          ? DwColors.gold.withValues(alpha: 0.7)
          : DwColors.teal.withValues(alpha: 0.7);
      fill = day.isGrand
          ? DwColors.gold.withValues(alpha: 0.22)
          : DwColors.teal.withValues(alpha: 0.22);
      labelColor = day.isGrand ? DwColors.gold : DwColors.teal;
    } else {
      ring = DwColors.onDark.withValues(alpha: 0.14);
      fill = Colors.transparent;
      labelColor = DwColors.onDarkFaint;
    }

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: ring, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Text(
            day.label,
            style: DwText.dm(
              size: 11,
              weight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isRest ? 'rest' : (day.scoreLabel ?? '—'),
          style: DwText.dm(
            size: 9,
            weight: FontWeight.w600,
            color: isRest || !attempted
                ? DwColors.onDarkFaint
                : DwColors.onDarkMuted,
          ),
        ),
      ],
    );
  }
}

/// Secondary Sunday dock — quiet “up next” for Monday, below week summary.
class _MondayDock extends StatelessWidget {
  const _MondayDock({
    required this.summary,
    required this.mondayTopics,
  });

  final DailyWarWeekSummary summary;
  final List<DailyWarTopicRef> mondayTopics;

  @override
  Widget build(BuildContext context) {
    final subjects = DailyWarCopy.subjectsLine(mondayTopics);
    final topicLine = mondayTopics.isEmpty
        ? 'Topics up Monday morning'
        : mondayTopics.map((t) => t.topic).take(2).join(' · ');

    final cta = summary.attemptedPartial && summary.missedTopics.isNotEmpty
        ? 'Catch up'
        : summary.attemptedAll
            ? 'Revise week'
            : 'Practice early';

    final practiceTopics =
        summary.attemptedPartial && summary.missedTopics.isNotEmpty
            ? [summary.missedTopics.first]
            : summary.attemptedAll
                ? summary.days
                    .where((d) => d.attempted)
                    .expand((d) => d.war?.topics ?? const <DailyWarTopicRef>[])
                    .toList()
                : mondayTopics;

    void openPractice() {
      if (practiceTopics.isEmpty) {
        context.push(dailyWarHistoryRoute());
        return;
      }
      unawaited(
        showDailyWarTopicsSheet(context: context, topics: practiceTopics),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: openPractice,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: DwColors.onDark.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'UP NEXT',
                    style: DwText.dm(
                      size: 10,
                      weight: FontWeight.w700,
                      color: DwColors.onDarkFaint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Monday · 9 PM',
                    style: DwText.dm(
                      size: 11,
                      weight: FontWeight.w600,
                      color: DwColors.onDarkMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    cta,
                    style: DwText.dm(
                      size: 11,
                      weight: FontWeight.w600,
                      color: DwColors.onDarkMuted,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: DwColors.onDarkFaint,
                  ),
                ],
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subjects,
                  style: DwText.dm(
                    size: 11,
                    weight: FontWeight.w600,
                    color: DwColors.onDarkMuted,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                topicLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DwText.dm(
                  size: 13,
                  weight: FontWeight.w600,
                  color: DwColors.onDarkMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
