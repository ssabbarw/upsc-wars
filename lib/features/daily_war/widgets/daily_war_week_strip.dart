import 'package:flutter/material.dart';

import '../domain/daily_war_schedule.dart';
import '../theme/daily_war_theme.dart';
import '../../../l10n/l10n.dart';

/// Mon–Sun rhythm strip for War detail (not home).
class DailyWarWeekStrip extends StatelessWidget {
  const DailyWarWeekStrip({super.key, required this.referenceIst});

  final DateTime referenceIst;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DailyWarSchedule.dateOnly(referenceIst);
    // Monday of this ISO week.
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayCell(
                  label: _labels[i],
                  day: monday.add(Duration(days: i)),
                  today: today,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.dwWeekStrip,
          style: DwText.dm(
            size: 11,
            weight: FontWeight.w500,
            color: DwColors.onDarkMuted,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.label, required this.day, required this.today});

  final String label;
  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final isPast = day.isBefore(today);
    final isSat = DailyWarSchedule.isSaturday(day);
    final isSun = DailyWarSchedule.isSunday(day);

    Color border;
    Color fill;
    Color text;
    Widget center;

    if (isSun) {
      border = DwColors.borderOnDark;
      fill = Colors.transparent;
      text = DwColors.onDarkFaint;
      center = Text(
        'off',
        style: DwText.dm(size: 9, weight: FontWeight.w600, color: text),
      );
    } else if (isSat) {
      border = DwColors.gold.withValues(alpha: isToday ? 0.9 : 0.45);
      fill = isToday
          ? DwColors.gold.withValues(alpha: 0.18)
          : Colors.transparent;
      text = DwColors.gold;
      center = Icon(
        Icons.autorenew_rounded,
        size: 14,
        color: text.withValues(alpha: isPast || isToday ? 1 : 0.55),
      );
    } else {
      final active = isPast || isToday;
      border = active
          ? DwColors.teal.withValues(alpha: isToday ? 0.9 : 0.5)
          : DwColors.borderOnDark;
      fill = isToday
          ? DwColors.teal.withValues(alpha: 0.18)
          : Colors.transparent;
      text = active ? DwColors.teal : DwColors.onDarkFaint;
      center = Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: active ? DwColors.teal : DwColors.onDarkFaint,
          shape: BoxShape.circle,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: DwText.dm(
                    size: 10,
                    weight: FontWeight.w700,
                    color: text,
                  ),
                ),
                const SizedBox(height: 2),
                center,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
