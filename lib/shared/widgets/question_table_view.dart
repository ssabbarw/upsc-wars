import 'package:flutter/material.dart';

import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';

/// Renders [QuestionTableData] (header, column labels, rows, footer) for stems
/// and review screens.
class QuestionTableView extends StatelessWidget {
  const QuestionTableView({super.key, required this.table});

  final QuestionTableData table;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final header = table.header?.trim();
    final footer = table.footer?.trim();
    var columns = table.columns;
    if (table.rows.isNotEmpty) {
      final firstRowLength = table.rows.first.length;
      if (columns.length == firstRowLength - 1) {
        columns = ['', ...columns];
      }
    }

    final columnCount = columns.length;
    if (columnCount == 0) return const SizedBox.shrink();

    final allRows = <List<String>>[
      columns,
      ...table.rows.map((row) {
        if (row.length == columnCount) return row;
        if (row.length < columnCount) {
          return [...row, ...List.filled(columnCount - row.length, '')];
        }
        return row.take(columnCount).toList();
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null && header.isNotEmpty) ...[
          SelectableCopySearchText(
            header,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: border, width: 0.5),
              columnWidths: {
                for (var i = 0; i < columnCount; i++)
                  i: const FlexColumnWidth(),
              },
              children: [
                for (var rowIndex = 0; rowIndex < allRows.length; rowIndex++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: rowIndex == 0
                          ? scheme.surfaceContainerLow
                          : scheme.surface,
                    ),
                    children: [
                      for (final cell in allRows[rowIndex])
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          child: SelectableCopySearchText(
                            cell,
                            textAlign: TextAlign.left,
                            style: (rowIndex == 0
                                    ? AppTextStyles.labelSm()
                                    : AppTextStyles.bodySm())
                                .copyWith(color: scheme.onSurface),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (footer != null && footer.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SelectableCopySearchText(
            footer,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
