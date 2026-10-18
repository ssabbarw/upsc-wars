import 'package:flutter/material.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_schedule.dart';
import '../theme/daily_war_theme.dart';
import '../../../l10n/l10n.dart';

/// “How Static War works” — opened only from the `?` control.
Future<void> showDailyWarHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const DismissOnScrimTap(child: _DailyWarHelpSheet()),
  );
}

class _DailyWarHelpSheet extends StatelessWidget {
  const _DailyWarHelpSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekdayMins = DailyWarSchedule.liveWindowMinutesFor(
      DailyWarSchedule.weekdayQuestionCount,
    );
    final grandMins = DailyWarSchedule.liveWindowMinutesFor(
      DailyWarSchedule.grandWarQuestionCount,
    );
    final rankClock = DailyWarSchedule.formatClock(
      DailyWarSchedule.rankTargetAt(DateTime(2026, 8, 3)),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l10n.dwHowWorks(DailyWarCopy.programName),
                  style: AppTextStyles.h2().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _HelpRow(
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFF1D9E75),
                  title: context.l10n.dwHelpLiveTitle,
                  body: context.l10n.dwHelpLiveBody(
                    DailyWarSchedule.weekdayQuestionCount,
                    weekdayMins,
                    DailyWarSchedule.grandWarQuestionCount,
                    grandMins,
                    DailyWarCopy.grandEventName,
                  ),
                ),
                _HelpRow(
                  icon: Icons.leaderboard_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: context.l10n.dwAirAt(rankClock),
                  body: context.l10n.dwHelpAirBody,
                ),
                _HelpRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: context.l10n.dwHelpRhythmTitle,
                  body: context.l10n.dwHelpRhythmBody(
                    DailyWarCopy.grandEventName,
                  ),
                ),
                _HelpRow(
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF6B7280),
                  title: context.l10n.dwHelpMissedTitle,
                  body: context.l10n.dwHelpMissedBody,
                  isLast: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: DwColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.commonGotIt,
                      style: AppTextStyles.label().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  body,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
