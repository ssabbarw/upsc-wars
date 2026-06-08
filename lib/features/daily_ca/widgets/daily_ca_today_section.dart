import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';
import 'package:intl/intl.dart';

/// Today's test card with a local 1s timer so the rest of the screen stays stable.
class DailyCaTodaySection extends StatefulWidget {
  const DailyCaTodaySection({
    super.key,
    required this.minDate,
    required this.todayCompleted,
    required this.launching,
    required this.onStartToday,
  });

  final DateTime minDate;
  final bool todayCompleted;
  final bool launching;
  final VoidCallback onStartToday;

  @override
  State<DailyCaTodaySection> createState() => _DailyCaTodaySectionState();
}

class _DailyCaTodaySectionState extends State<DailyCaTodaySection> {
  late DateTime _ist;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ist = DailyCaSchedule.nowIst();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ist = DailyCaSchedule.nowIst());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final minDate = widget.minDate;
    final minDateLabel = DateFormat('d MMM yyyy').format(minDate);
    final todayAllowed = DailyCaSchedule.isOnOrAfterMinDate(_ist, minDate);
    final todayIsTestDay = DailyCaSchedule.isTestDay(_ist);
    final todayPublished = DailyCaSchedule.isPublishedForDate(_ist);
    final countdown = DailyCaSchedule.timeUntilNextPublish(referenceIst: _ist);
    final countdownLabel = DailyCaSchedule.formatCountdown(countdown);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "TODAY'S TEST",
            style: AppTextStyles.caption().copyWith(
              color: isDark ? AppColors.infoTextDark : AppColors.infoText,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!todayAllowed)
            Text(
              'Daily tests start from $minDateLabel.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else if (!todayIsTestDay)
            Text(
              'Sundays are rest days — no test today.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else if (!todayPublished)
            Text(
              'Available at 9:00 PM IST · $countdownLabel remaining',
              style: AppTextStyles.body().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              widget.todayCompleted
                  ? 'Completed · tap to revise'
                  : "10 MCQs from today's news",
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: (!todayAllowed ||
                    !todayIsTestDay ||
                    !todayPublished ||
                    widget.launching)
                ? null
                : widget.onStartToday,
            icon: widget.launching
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : Icon(
                    widget.todayCompleted
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                  ),
            label: Text(
              !todayAllowed
                  ? 'Not started yet'
                  : !todayIsTestDay
                  ? 'No test today'
                  : !todayPublished
                  ? 'Opens at 9 PM'
                  : widget.todayCompleted
                  ? "Revise today's test"
                  : "Start today's test",
            ),
          ),
          if (todayAllowed && todayIsTestDay && !todayPublished) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Next test in $countdownLabel',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
