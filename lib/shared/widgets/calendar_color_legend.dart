import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class CalendarLegendSwatch {
  const CalendarLegendSwatch({
    required this.label,
    this.fill,
    this.border,
    this.dot,
  });

  final String label;
  final Color? fill;
  final Color? border;
  final Color? dot;
}

class CalendarColorLegend extends StatelessWidget {
  const CalendarColorLegend({super.key, required this.items});

  final List<CalendarLegendSwatch> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = Theme.of(context).brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item.fill,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: item.border ?? outline,
                    width: item.border != null ? 1.4 : 0.8,
                  ),
                ),
                child: item.dot == null
                    ? null
                    : Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: item.dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
