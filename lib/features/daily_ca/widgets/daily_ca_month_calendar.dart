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
  });

  final int year;
  final int month;
  final Set<String> completedDates;
  final void Function(String isoDate) onDateTap;
  /// Earliest selectable date on the calendar (date-only).
  final DateTime minDate;
  final DateTime? nowIst;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final reference = nowIst ?? DailyCaSchedule.nowIst();
    final todayIso = DailyCaSchedule.formatIsoDate(reference);
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 0 … Sunday = 6
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;

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
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final day = index - leadingBlanks + 1;
            final istDate = DateTime(year, month, day);
            final iso = DailyCaSchedule.formatIsoDate(istDate);
            final isOffDay = DailyCaSchedule.isSaturday(istDate);
            final isToday = iso == todayIso;
            final isPublished = DailyCaSchedule.isPublishedForDate(
              istDate,
              referenceIst: reference,
            );
            final isCompleted = completedDates.contains(iso);
            final isBeforeMin = !DailyCaSchedule.isOnOrAfterMinDate(
              istDate,
              minDate,
            );
            final canTap = !isOffDay && !isBeforeMin && isPublished;

            Color? fill;
            Color textColor = scheme.onSurface;
            if (isOffDay || isBeforeMin) {
              textColor = scheme.onSurfaceVariant.withValues(alpha: 0.45);
            } else if (!isPublished) {
              textColor = scheme.onSurfaceVariant.withValues(alpha: 0.55);
            } else if (isCompleted) {
              fill = isDark ? AppColors.correctBgDark : AppColors.correctBg;
              textColor = isDark ? AppColors.correctTextDark : AppColors.correctText;
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canTap ? () => onDateTap(iso) : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Ink(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isToday ? AppColors.primary : border,
                      width: isToday ? 1.5 : 0.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.label().copyWith(
                          color: textColor,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isCompleted)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.correct,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
