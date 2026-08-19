import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/calendar_color_legend.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';
import '../theme/daily_war_theme.dart';

enum DailyWarDayKind { rest, future, upcoming, live, done, missed, empty }

class DailyWarMonthCalendar extends StatelessWidget {
  const DailyWarMonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.warsByDate,
    required this.submittedDates,
    required this.onDateTap,
    required this.minDate,
    required this.todayIso,
    required this.liveDateId,
    this.nowIst,
  });

  final int year;
  final int month;
  final Map<String, DailyWarDoc> warsByDate;
  final Set<String> submittedDates;
  final void Function(String isoDate) onDateTap;
  final DateTime minDate;
  final String todayIso;
  final String? liveDateId;
  final DateTime? nowIst;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  DailyWarDayKind _kind(DateTime istDate, String iso) {
    final reference = nowIst ?? DailyWarSchedule.nowIst();
    if (DailyWarSchedule.isWarOffDay(istDate)) return DailyWarDayKind.rest;
    if (istDate.isAfter(DailyWarSchedule.dateOnly(reference))) {
      return DailyWarDayKind.future;
    }
    if (istDate.isBefore(DailyWarSchedule.dateOnly(minDate))) {
      return DailyWarDayKind.empty;
    }
    if (submittedDates.contains(iso)) return DailyWarDayKind.done;
    if (iso == liveDateId) return DailyWarDayKind.live;
    if (iso == todayIso) return DailyWarDayKind.upcoming;
    return DailyWarDayKind.missed;
  }

  bool _canTap(DailyWarDayKind kind) {
    switch (kind) {
      case DailyWarDayKind.done:
      case DailyWarDayKind.missed:
      case DailyWarDayKind.live:
      case DailyWarDayKind.upcoming:
        return true;
      case DailyWarDayKind.rest:
      case DailyWarDayKind.future:
      case DailyWarDayKind.empty:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
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
                      color: label == 'Sun'
                          ? (isDark
                                ? AppColors.warningTextDark
                                : AppColors.warningText)
                          : label == 'Sat'
                          ? DwColors.gold
                          : scheme.onSurfaceVariant,
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
            final iso = DailyWarSchedule.formatIsoDate(istDate);
            final kind = _kind(istDate, iso);
            final isToday = iso == todayIso;
            final isGrand = DailyWarSchedule.isGrandWarDay(istDate);
            final attempted = submittedDates.contains(iso);
            final canTap = _canTap(kind);

            Color? fill;
            Color textColor = scheme.onSurface;
            var borderColor = isToday ? AppColors.primary : border;
            var borderWidth = isToday ? 1.5 : 0.5;

            switch (kind) {
              case DailyWarDayKind.rest:
                fill = isDark ? AppColors.warningBgDark : AppColors.warningBg;
                textColor = isDark
                    ? AppColors.warningTextDark
                    : AppColors.warningText;
              case DailyWarDayKind.future:
              case DailyWarDayKind.empty:
                textColor = scheme.onSurfaceVariant.withValues(alpha: 0.45);
              case DailyWarDayKind.upcoming:
                textColor = scheme.onSurface;
              case DailyWarDayKind.live:
                borderColor = DwColors.crimsonBright;
                borderWidth = 1.6;
                fill = isDark
                    ? DwColors.crimson.withValues(alpha: 0.18)
                    : DwColors.crimsonSoft;
                textColor = isDark
                    ? DwColors.crimsonBright
                    : DwColors.crimson;
              case DailyWarDayKind.done:
              case DailyWarDayKind.missed:
                textColor = scheme.onSurfaceVariant;
            }

            if (attempted) {
              fill = AppColors.primary;
              textColor = AppColors.onPrimary;
              borderColor = AppColors.primaryDark;
              borderWidth = isToday ? 1.8 : 1.2;
            }

            if (isGrand && kind != DailyWarDayKind.rest) {
              borderColor = DwColors.gold;
              if (borderWidth < 1.2) borderWidth = 1.2;
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
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.label().copyWith(
                          color: textColor,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (attempted)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      if (warsByDate[iso]?.isGrand == true ||
                          (isGrand && kind != DailyWarDayKind.rest))
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: DwColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CalendarColorLegend(
          items: [
            CalendarLegendSwatch(
              label: 'Attempted',
              fill: AppColors.primary,
              border: AppColors.primaryDark,
            ),
            CalendarLegendSwatch(
              label: 'Live',
              fill: isDark
                  ? DwColors.crimson.withValues(alpha: 0.18)
                  : DwColors.crimsonSoft,
              border: DwColors.crimsonBright,
            ),
            CalendarLegendSwatch(
              label: 'Grand War',
              border: DwColors.gold,
              dot: DwColors.gold,
            ),
            CalendarLegendSwatch(
              label: 'Sunday',
              fill: isDark ? AppColors.warningBgDark : AppColors.warningBg,
              border: isDark
                  ? AppColors.warningTextDark
                  : AppColors.warningText,
            ),
            const CalendarLegendSwatch(label: 'Today', border: AppColors.primary),
          ],
        ),
      ],
    );
  }
}
