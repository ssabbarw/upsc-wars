import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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
    final sundayFill = isDark ? AppColors.warningBgDark : AppColors.warningBg;
    final sundayText = isDark
        ? AppColors.warningTextDark
        : AppColors.warningText;
    final cellFill = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceTertiaryLight;
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.05,
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

            Color fill = cellFill;
            Color textColor = scheme.onSurface;
            Color? ring;

            if (isToday) {
              fill = AppColors.primary;
              textColor = AppColors.onPrimary;
              ring = AppColors.primaryDark;
            } else if (kind == DailyWarDayKind.rest) {
              fill = sundayFill;
              textColor = sundayText;
            } else if (kind == DailyWarDayKind.empty ||
                kind == DailyWarDayKind.future) {
              textColor = scheme.onSurfaceVariant.withValues(alpha: 0.4);
            } else if (kind == DailyWarDayKind.live) {
              textColor = AppColors.primary;
              ring = AppColors.primary;
            } else if (attempted || kind == DailyWarDayKind.done) {
              textColor = AppColors.primary;
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
                    border: ring == null
                        ? null
                        : Border.all(color: ring, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.labelSm().copyWith(
                          color: textColor,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (warsByDate[iso]?.isGrand == true ||
                          (isGrand && kind != DailyWarDayKind.rest))
                        Positioned(
                          bottom: 4,
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
      ],
    );
  }
}
