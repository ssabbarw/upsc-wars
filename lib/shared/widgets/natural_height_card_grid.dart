import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Multi-column card grid for tablet widths where each row takes its cards'
/// natural height (no fixed aspect ratio, so wide screens don't make tall,
/// empty cards). Cards in a row match the tallest one.
class NaturalHeightCardGrid extends StatelessWidget {
  const NaturalHeightCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.primary,
    this.shrinkWrap = false,
    this.spacing = AppSpacing.sm,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool shrinkWrap;
  final double spacing;

  static int columnsFor(double width) => width >= 900 ? 3 : 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(constraints.maxWidth);
        final rowCount = (itemCount + columns - 1) ~/ columns;
        return ListView.separated(
          primary: primary,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          itemCount: rowCount,
          separatorBuilder: (_, _) => SizedBox(height: spacing),
          itemBuilder: (context, row) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: spacing),
                  Expanded(
                    child: row * columns + c < itemCount
                        ? itemBuilder(context, row * columns + c)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
