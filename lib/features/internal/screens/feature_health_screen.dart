import 'dart:math' as math;

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
                style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
              ),
            );
          }

          Map<int, TableColumnWidth> columnWidthsForContent(
            List<List<String>> rows,
          ) {
            if (rows.isEmpty) return const {};
            final columnCount = rows.first.length;

            int maxLenForCol(int col) {
              var maxLen = 0;
              for (final r in rows) {
                if (col >= r.length) continue;
                final v = r[col].trim();
                if (v.length > maxLen) maxLen = v.length;
              }
              return maxLen;
            }

            bool isTightNumericOrTiny(int col, int maxLen) {
              if (maxLen == 0) return true;
              if (maxLen <= 3) return true;
              var allNumeric = true;
              var anyNonEmpty = false;
              for (final r in rows) {
                if (col >= r.length) continue;
                final v = r[col].trim();
                if (v.isEmpty) continue;
                anyNonEmpty = true;
                if (!RegExp(r'^\d+$').hasMatch(v)) allNumeric = false;
              }
              return anyNonEmpty && allNumeric && maxLen <= 6;
            }

            double flexWeightFor(int maxLen) {
              if (maxLen <= 0) return 1;
              final w = math.sqrt(maxLen.toDouble());
              return w.clamp(1.0, 8.0);
            }

            final maxLens = List<int>.generate(columnCount, maxLenForCol);

            return <int, TableColumnWidth>{
              for (var i = 0; i < columnCount; i++)
                i: isTightNumericOrTiny(i, maxLens[i])
                    ? const IntrinsicColumnWidth()
                    : FlexColumnWidth(flexWeightFor(maxLens[i])),
            };
          }

          final dataRows = <List<String>>[
            ['Feature', 'Views', 'Starts', 'Done', 'Repeat'],
            for (final entry in _kFeatureRows)
              [
                entry.$2,
                '${byName[entry.$1]?.totalViews ?? 0}',
                '${byName[entry.$1]?.totalStarts ?? 0}',
                '${byName[entry.$1]?.totalCompletions ?? 0}',
                '${_repeatUsage(byName[entry.$1])}',
              ],
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Table(
              border: TableBorder.all(color: scheme.outlineVariant, width: 0.5),
              columnWidths: columnWidthsForContent(dataRows),
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
                      cell('${byName[entry.$1]?.totalViews ?? 0}', right: true),
                      cell(
                        '${byName[entry.$1]?.totalStarts ?? 0}',
                        right: true,
                      ),
                      cell(
                        '${byName[entry.$1]?.totalCompletions ?? 0}',
                        right: true,
                      ),
                      cell('${_repeatUsage(byName[entry.$1])}', right: true),
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
