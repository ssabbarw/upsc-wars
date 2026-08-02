import 'package:flutter/material.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_war_schedule.dart';
import '../theme/daily_war_theme.dart';

/// “How Daily War works” — opened only from the `?` control.
Future<void> showDailyWarHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _DailyWarHelpSheet(),
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
    // Any Mon–Fri date — clock for weekday live close (9:20 PM).
    final liveEndClock = DailyWarSchedule.formatClock(
      DailyWarSchedule.liveEndsAt(
        DateTime(2026, 8, 3),
        questionCount: DailyWarSchedule.weekdayQuestionCount,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'How Daily War works',
                  style: AppTextStyles.h2().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One live paper a night on topics announced in advance. '
                  'Keep turning up and the syllabus closes itself.',
                  style: AppTextStyles.body().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _HelpRow(
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFF1D9E75),
                  title: 'Live at 9:00 PM',
                  body:
                      'Weeknights: ${DailyWarSchedule.weekdayQuestionCount} questions '
                      'in $weekdayMins minutes. Saturday Grand War: '
                      '${DailyWarSchedule.grandWarQuestionCount} questions '
                      'in $grandMins minutes. Same paper for everyone.',
                ),
                _HelpRow(
                  icon: Icons.leaderboard_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Ranks after $liveEndClock',
                  body:
                      'Ranked by score first, then time taken. '
                      'One attempt counts for the All-India rank.',
                ),
                _HelpRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'The week has a rhythm',
                  body:
                      'Monday to Friday bring two new topics each night. '
                      'Saturday revises the week (Grand War). Sunday is off.',
                ),
                _HelpRow(
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF6B7280),
                  title: 'Missed a night?',
                  body:
                      'The paper stays open for practice, but it earns no rank '
                      'and breaks your War streak.',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Two topics a night, five nights a week, with Saturday to '
                    'consolidate. No marathon sessions, no catch-up weekends.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                      'Got it',
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
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
