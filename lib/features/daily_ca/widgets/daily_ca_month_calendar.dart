import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';

class DailyCaMonthCalendar extends StatelessWidget {
  const DailyCaMonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.completedDates,
    required this.onDateTap,
    required this.minDate,
    this.nowIst,
    this.paperIso,
  });

  final int year;
  final int month;
  final Set<String> completedDates;
  final void Function(String isoDate) onDateTap;

  /// Earliest selectable date on the calendar (date-only).
  final DateTime minDate;
  final DateTime? nowIst;

  /// News date of the open paper — drawn in primary text when not today.
  final String? paperIso;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sundayFill = isDark ? AppColors.warningBgDark : AppColors.warningBg;
    final sundayText = isDark
        ? AppColors.warningTextDark
        : AppColors.warningText;
    final cellFill = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceTertiaryLight;
    final reference = nowIst ?? DailyCaSchedule.nowIst();
    final todayIso = DailyCaSchedule.formatIsoDate(reference);
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 0 … Sunday = 6
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
    final itemCount = leadingBlanks + daysInMonth;
    final rowCount = (itemCount / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTextStyles.caption().copyWith(
                      color: label == 'Sun'
                          ? sundayText
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: Column(
            children: [
              for (var row = 0; row < rowCount; row++) ...[
                if (row > 0) const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0; col < 7; col++) ...[
                        if (col > 0) const SizedBox(width: 4),
                        Expanded(
                          child: _DayCell(
                            index: row * 7 + col,
                            leadingBlanks: leadingBlanks,
                            year: year,
                            month: month,
                            todayIso: todayIso,
                            paperIso: paperIso,
                            completedDates: completedDates,
                            minDate: minDate,
                            reference: reference,
                            cellFill: cellFill,
                            sundayFill: sundayFill,
                            sundayText: sundayText,
                            onSurface: scheme.onSurface,
                            onSurfaceVariant: scheme.onSurfaceVariant,
                            onDateTap: onDateTap,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.leadingBlanks,
    required this.year,
    required this.month,
    required this.todayIso,
    required this.paperIso,
    required this.completedDates,
    required this.minDate,
    required this.reference,
    required this.cellFill,
    required this.sundayFill,
    required this.sundayText,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onDateTap,
  });

  final int index;
  final int leadingBlanks;
  final int year;
  final int month;
  final String todayIso;
  final String? paperIso;
  final Set<String> completedDates;
  final DateTime minDate;
  final DateTime reference;
  final Color cellFill;
  final Color sundayFill;
  final Color sundayText;
  final Color onSurface;
  final Color onSurfaceVariant;
  final void Function(String isoDate) onDateTap;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (index < leadingBlanks || index - leadingBlanks + 1 > daysInMonth) {
      return const SizedBox.expand();
    }

    final day = index - leadingBlanks + 1;
    final istDate = DateTime(year, month, day);
    final iso = DailyCaSchedule.formatIsoDate(istDate);
    final isOffDay = DailyCaSchedule.isSunday(istDate);
    final isToday = iso == todayIso;
    final isPaper = iso == paperIso;
    final isPublished = DailyCaSchedule.isPublishedForDate(
      istDate,
      referenceIst: reference,
    );
    final isCompleted = completedDates.contains(iso);
    final isBeforeMin = !DailyCaSchedule.isOnOrAfterMinDate(istDate, minDate);
    final canTap = DailyCaSchedule.isCalendarDaySelectable(
      istDate,
      minDate: minDate,
      referenceIst: reference,
    );

    Color fill = cellFill;
    Color textColor = onSurface;
    Color? ring;

    if (isToday) {
      fill = AppColors.primary;
      textColor = AppColors.onPrimary;
      ring = AppColors.primaryDark;
    } else if (isOffDay) {
      fill = sundayFill;
      textColor = sundayText;
    } else if (isBeforeMin) {
      textColor = onSurfaceVariant.withValues(alpha: 0.4);
    } else if (isCompleted || isPaper) {
      textColor = AppColors.primary;
    } else if (!isPublished) {
      textColor = onSurfaceVariant.withValues(alpha: 0.5);
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: canTap ? () => onDateTap(iso) : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: ring == null ? null : Border.all(color: ring, width: 1.5),
          ),
          child: Center(
            child: Text(
              '$day',
              style: AppTextStyles.labelSm().copyWith(
                color: textColor,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

