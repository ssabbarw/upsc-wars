import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/daily_war_week_summary.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_badge_chip.dart';

/// Compact Sunday progress — nights, accuracy, danger topics, badges.
Future<void> showDailyWarWeekProgressSheet({
  required BuildContext context,
  required DailyWarWeekSummary summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WeekProgressSheet(summary: summary),
  );
}

class _WeekProgressSheet extends ConsumerWidget {
  const _WeekProgressSheet({required this.summary});

  final DailyWarWeekSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final monday = summary.monday;
    final saturday = monday.add(const Duration(days: 5));
    final range =
        '${DateFormat('d MMM').format(monday)}'
        ' – ${DateFormat('d MMM').format(saturday)}';

    final dateIds = [
      for (final d in summary.days)
        if (!d.isRest) DailyWarSchedule.formatIsoDate(d.date),
    ];

    final dangerAsync = ref.watch(
      dailyWarWeekConfidentWrongProvider(dateIds.join('|')),
    );

    return DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Your week in War',
                      style: AppTextStyles.h3().copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      range,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BigStat(
                            value:
                                '${summary.attemptedNights}/${summary.warNights}',
                            label: 'nights attempted',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BigStat(
                            value: summary.accuracyPct == null
                                ? '—'
                                : '${summary.accuracyPct!.round()}%',
                            label: 'accuracy',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Confidently wrong',
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topics where you marked Sure / Educated guess and missed.',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    dangerAsync.when(
                      loading: () => Text(
                        'Loading…',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      error: (_, _) => Text(
                        'Couldn\'t load danger topics.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      data: (topics) {
                        if (topics.isEmpty) {
                          return Text(
                            summary.attemptedNone
                                ? 'No attempts this week yet.'
                                : 'None this week — keep that map clean.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final t in topics)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.subject.toUpperCase(),
                                            style: AppTextStyles.caption()
                                                .copyWith(
                                                  color: DwColors.crimson,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                          Text(
                                            t.topic,
                                            style: AppTextStyles.bodySm()
                                                .copyWith(
                                                  color: scheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '×${t.count}',
                                      style: AppTextStyles.label().copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: DwColors.crimson,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Badges earned',
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (summary.badgeCounts.isEmpty)
                      Text(
                        summary.attemptedNone
                            ? 'Show up Monday to start collecting.'
                            : 'No badges this week.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final b in summary.badgeCounts)
                            SizedBox(
                              width: 84,
                              child: Column(
                                children: [
                                  DailyWarBadgeChip(
                                    badgeId: b.badgeId,
                                    size: 44,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption().copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '×${b.count}',
                                    style: AppTextStyles.caption().copyWith(
                                      color: DwColors.teal,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h3().copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confidently-wrong topics for Daily War nights in [joinedIds] (`date|date|…`).
final dailyWarWeekConfidentWrongProvider = FutureProvider.autoDispose
    .family<List<({String subject, String topic, int count})>, String>((
      ref,
      joinedIds,
    ) async {
      final dateIds = joinedIds.isEmpty
          ? const <String>[]
          : joinedIds.split('|');
      if (dateIds.isEmpty) return const [];
      final db = ref.watch(userDatabaseProvider);
      final placeholders = List.filled(dateIds.length, '?').join(', ');
      final rows = await db
          .customSelect(
            '''
        SELECT q.subject AS subject, q.topic AS topic, COUNT(*) AS c
        FROM attempts a
        INNER JOIN sessions s ON s.id = a.session_id
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE s.subject = ?
          AND s.topic IN ($placeholders)
          AND a.status = 'wrong'
          AND a.confidence IN (?, ?)
        GROUP BY q.subject, q.topic
        ORDER BY c DESC
        LIMIT 12
        ''',
            variables: [
              Variable.withString(DailyWarConstants.sessionSubject),
              for (final id in dateIds) Variable.withString(id),
              Variable.withString(AnswerConfidence.verySure),
              Variable.withString(AnswerConfidence.somewhatSure),
            ],
            readsFrom: {db.sessionQuestions, db.sessions, db.questions},
          )
          .get();

      return [
        for (final r in rows)
          (
            subject: r.read<String>('subject'),
            topic: r.read<String>('topic'),
            count: r.read<int>('c'),
          ),
      ];
    });
