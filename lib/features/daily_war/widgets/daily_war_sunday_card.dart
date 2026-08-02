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

/// Compact Sunday home hero — week strip + Monday topics.
class DailyWarSundayCard extends ConsumerWidget {
  const DailyWarSundayCard({super.key});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 14,
              color: DwColors.onDarkMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'SUNDAY · NO WAR TONIGHT',
                style: DwText.eyebrow(color: DwColors.onDarkMuted),
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
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _headline(summary),
          style: DwText.dm(size: 16, weight: FontWeight.w700, height: 1.25),
        ),
        const SizedBox(height: 10),
        _WeekScoreStrip(days: summary.days),
        const SizedBox(height: 10),
        _WeekSummaryPreview(summary: summary),
        const SizedBox(height: 10),
        _MondayDock(
          summary: summary,
          mondayTopics: mondayTopics,
        ),
      ],
    );
  }

  static String _headline(DailyWarWeekSummary s) {
    if (s.attemptedNone) {
      final n = s.missedTopics.length;
      return n > 0
          ? 'Quiet week · $n topics went by'
          : 'Quiet week · rest today';
    }
    if (s.attemptedAll) {
      return 'Week ${s.weekNumber} done · streak safe';
    }
    return '${s.attemptedNights}/${s.warNights} nights · '
        '${s.topicsCovered} topics landed';
  }
}

/// Compact tappable preview of week stats → full progress sheet.
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

    return Material(
      color: DwColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => unawaited(
          showDailyWarWeekProgressSheet(
            context: context,
            summary: summary,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DwColors.borderOnDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PreviewChip(
                      value: '${summary.attemptedNights}/${summary.warNights}',
                      label: 'nights',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _PreviewChip(
                      value: accuracy,
                      label: 'accuracy',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _PreviewChip(
                      value: dangerCount == 0 ? '0' : '$dangerCount',
                      label: 'danger',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _PreviewChip(
                      value: '$badgeCount',
                      label: 'badges',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'See full week summary',
                    style: DwText.dm(
                      size: 11,
                      weight: FontWeight.w700,
                      color: DwColors.crimsonBright,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: DwColors.crimsonBright,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: DwText.dm(size: 15, weight: FontWeight.w800),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: DwText.dm(
            size: 10,
            weight: FontWeight.w600,
            color: DwColors.onDarkMuted,
          ),
        ),
      ],
    );
  }
}

class _WeekScoreStrip extends StatelessWidget {
  const _WeekScoreStrip({required this.days});

  final List<DailyWarWeekDayCell> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _ScoreCell(day: d),
            ),
          ),
      ],
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.day});

  final DailyWarWeekDayCell day;

  @override
  Widget build(BuildContext context) {
    final attempted = day.attempted;
    final isRest = day.isRest;
    final score = day.scoreLabel;

    final Color border;
    final Color fill;
    final Color labelColor;
    if (isRest) {
      border = DwColors.borderOnDark;
      fill = Colors.transparent;
      labelColor = DwColors.onDarkFaint;
    } else if (attempted) {
      border = day.isGrand
          ? DwColors.gold.withValues(alpha: 0.55)
          : DwColors.teal.withValues(alpha: 0.55);
      fill = day.isGrand
          ? DwColors.gold.withValues(alpha: 0.14)
          : DwColors.teal.withValues(alpha: 0.14);
      labelColor = day.isGrand ? DwColors.gold : DwColors.teal;
    } else {
      border = DwColors.borderOnDark;
      fill = Colors.transparent;
      labelColor = DwColors.onDarkFaint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            day.label,
            style: DwText.dm(
              size: 9,
              weight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isRest ? 'rest' : (score ?? '—'),
            style: DwText.dm(
              size: 9,
              weight: FontWeight.w700,
              color: isRest || !attempted
                  ? DwColors.onDarkFaint
                  : DwColors.onDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Monday topics + one CTA — replaces banner + big button + nested card.
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
        ? 'Catch up one topic'
        : summary.attemptedAll
            ? 'Revise the week'
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
      color: DwColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: openPractice,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DwColors.borderOnDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'NEXT · MONDAY 9 PM',
                      style: DwText.dm(
                        size: 10,
                        weight: FontWeight.w800,
                        color: DwColors.onDarkMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    cta,
                    style: DwText.dm(
                      size: 11,
                      weight: FontWeight.w700,
                      color: DwColors.teal,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: DwColors.teal,
                  ),
                ],
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subjects.toUpperCase(),
                  style: DwText.dm(
                    size: 11,
                    weight: FontWeight.w700,
                    color: DwColors.crimsonBright,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                topicLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DwText.dm(
                  size: 13,
                  weight: FontWeight.w700,
                  color: DwColors.onDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
