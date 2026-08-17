import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';
import 'daily_ca_unavailable_sheet.dart';

/// The paper quiz to attempt now, with a local 1s timer so the rest of the
/// screen stays stable while the countdown ticks.
class DailyCaTodaySection extends StatefulWidget {
  const DailyCaTodaySection({
    super.key,
    required this.minDate,
    required this.paperDate,
    required this.paperCompleted,
    required this.launching,
    required this.onStartPaper,
    this.questionsReady = true,
  });

  final DateTime minDate;

  /// News date of the open paper quiz, or null when nothing has opened.
  final DateTime? paperDate;
  final bool paperCompleted;
  final bool launching;

  /// False when the scheduled paper has no live questions yet.
  final bool questionsReady;
  final VoidCallback? onStartPaper;

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

    final paperDate = widget.paperDate;
    final allowed = paperDate != null &&
        DailyCaSchedule.isOnOrAfterMinDate(paperDate, widget.minDate);
    final isTodaysPaper = paperDate != null &&
        DailyCaSchedule.isTodaysPaper(paperDate, referenceIst: _ist);
    final countdownLabel = DailyCaSchedule.formatCountdown(
      DailyCaSchedule.timeUntilNextOpen(referenceIst: _ist),
    );

    final String headline;
    if (!allowed) {
      headline = 'Daily tests start from '
          '${DateFormat('d MMM yyyy').format(widget.minDate)}.';
    } else if (!widget.questionsReady) {
      headline = 'Questions aren\'t up yet. Tomorrow\'s paper opens at 6 AM.';
    } else if (isTodaysPaper) {
      headline = "10 MCQs from today's newspaper";
    } else {
      headline = '10 MCQs from the '
          '${DateFormat('d MMM').format(paperDate)} paper';
    }

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
            "TODAY'S PAPER",
            style: AppTextStyles.caption().copyWith(
              color: isDark ? AppColors.infoTextDark : AppColors.infoText,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.paperCompleted ? 'Completed · tap to revise' : headline,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: widget.launching
                ? null
                : !allowed
                ? null
                : widget.questionsReady
                ? widget.onStartPaper
                : () {
                    showDailyCaUnavailableSheet(
                      context: context,
                      availableFrom: DailyCaSchedule.nextOpensAt(
                        referenceIst: _ist,
                      ),
                      onSeeHistory: () {},
                    );
                  },
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
                    widget.paperCompleted
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                  ),
            label: Text(
              !allowed
                  ? 'Not started yet'
                  : !widget.questionsReady
                  ? 'Coming soon'
                  : widget.paperCompleted
                  ? 'Revise this paper'
                  : 'Start the quiz',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Next paper opens in $countdownLabel',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
