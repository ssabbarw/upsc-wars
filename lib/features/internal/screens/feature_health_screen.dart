import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/user_db.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Rows shown even before any local aggregates exist.
const _kFeatureRows = <(String id, String label)>[
  ('mcq_battle', 'MCQ Battle'),
  ('pyq_mode', 'PYQ Mode'),
  ('flashcards', 'Flashcards'),
  ('revision_mode', 'Revision mode'),
  ('trap_awareness', 'Trap awareness'),
  ('daily_quiz', 'Daily / subject quiz'),
  ('insights_dashboard', 'Insights / weak areas'),
];

/// Minimal internal table for roadmap decisions (local SQLite aggregates).
class FeatureHealthScreen extends ConsumerWidget {
  const FeatureHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final db = ref.watch(userDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feature health')),
      body: StreamBuilder<List<UserFeatureStat>>(
        stream: db.userFeatureStatsDao.watchAll(),
        builder: (context, snap) {
          final rows = snap.data ?? const <UserFeatureStat>[];
          final byName = {for (final r in rows) r.featureName: r};

          Widget cell(String text, {bool right = false}) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                text,
                textAlign: right ? TextAlign.right : TextAlign.start,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurface,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Table(
              border: TableBorder.all(color: scheme.outlineVariant, width: 0.5),
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.1),
                4: FlexColumnWidth(1.1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: scheme.surfaceContainerLow),
                  children: [
                    cell('Feature'),
                    cell('Views', right: true),
                    cell('Starts', right: true),
                    cell('Done', right: true),
                    cell('Repeat', right: true),
                  ],
                ),
                for (final entry in _kFeatureRows)
                  TableRow(
                    children: [
                      cell(entry.$2),
                      cell(
                        '${byName[entry.$1]?.totalViews ?? 0}',
                        right: true,
                      ),
                      cell(
                        '${byName[entry.$1]?.totalStarts ?? 0}',
                        right: true,
                      ),
                      cell(
                        '${byName[entry.$1]?.totalCompletions ?? 0}',
                        right: true,
                      ),
                      cell(
                        '${_repeatUsage(byName[entry.$1])}',
                        right: true,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Sessions started beyond the first exposure (starts − 1), floored at 0.
  static int _repeatUsage(UserFeatureStat? row) {
    if (row == null) return 0;
    return (row.totalStarts - 1).clamp(0, 1 << 30);
  }
}
