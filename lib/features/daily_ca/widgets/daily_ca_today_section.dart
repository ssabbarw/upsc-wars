import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';
import '../domain/daily_ca_source_links.dart';
import 'daily_ca_source_link_row.dart';
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
    this.onRevisePaper,
    this.onViewResults,
    this.onViewRankings,
    this.questionsReady = true,
    this.compact = false,
  });

  final DateTime minDate;

  /// News date of the open paper quiz, or null when nothing has opened.
  final DateTime? paperDate;
  final bool paperCompleted;
  final bool launching;

  /// False when the scheduled paper has no live questions yet.
  final bool questionsReady;
  final VoidCallback? onStartPaper;

  /// After the first attempt: reopen the paper to review answers.
  final VoidCallback? onRevisePaper;

  /// After the first attempt: jump to the last completed session's results.
  final VoidCallback? onViewResults;

  /// After the first attempt: open the rank board.
  final VoidCallback? onViewRankings;

  /// Tighter padding and type so the hub fits a short phone.
  final bool compact;

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
    final compact = widget.compact;
    final info = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final infoSoft = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final pad = compact ? AppSpacing.md : AppSpacing.lg;
    final gap = compact ? AppSpacing.sm : AppSpacing.md;

    final paperDate = widget.paperDate;
    final allowed =
        paperDate != null &&
        DailyCaSchedule.isOnOrAfterMinDate(paperDate, widget.minDate);
    final isTodaysPaper =
        paperDate != null &&
        DailyCaSchedule.isTodaysPaper(paperDate, referenceIst: _ist);
    final nextOpen = DailyCaSchedule.nextOpensAt(referenceIst: _ist);
    final countdownLabel = DailyCaSchedule.formatCountdownHms(
      DailyCaSchedule.timeUntilNextOpen(referenceIst: _ist),
    );
    final nextIsToday =
        DailyCaSchedule.dateOnly(nextOpen) == DailyCaSchedule.dateOnly(_ist);
    final nextCopy = nextIsToday
        ? 'Today\'s test opens at 6 AM'
        : 'Tomorrow\'s test opens at 6 AM';

    final String headline;
    if (!allowed) {
      headline =
          'Daily tests start from '
          '${DateFormat('d MMM yyyy').format(widget.minDate)}.';
    } else if (!widget.questionsReady) {
      headline = nextIsToday
          ? 'Today\'s test will be available soon.'
          : 'Today\'s test will be available tomorrow morning.';
    } else if (widget.paperCompleted) {
      headline = 'Quiz done. Open the explanations if a line still nags.';
    } else if (isTodaysPaper) {
      headline = 'Current affairs test from yesterday\'s news.';
    } else {
      headline =
          '10 MCQs from the ${DateFormat('d MMM').format(paperDate)} paper';
    }

    final reviseCopy = isTodaysPaper
        ? "You can revise yesterday's current affairs from these links."
        : 'You can revise this day\'s current affairs from these links.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, compact ? 10 : pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: info,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.newspaper_rounded,
                              size: 13,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "TODAY'S PAPER",
                            style: AppTextStyles.caption().copyWith(
                              color: info,
                              letterSpacing: 0.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Text(
                        headline,
                        style:
                            (compact ? AppTextStyles.h3() : AppTextStyles.h2())
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  height: 1.25,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 28,
                        height: 3,
                        decoration: BoxDecoration(
                          color: info,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      if (allowed)
                        Text(
                          reviseCopy,
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                  if (allowed) ...[
                    SizedBox(height: gap),
                    for (final link in DailyCaSourceLinks.forDate(
                      paperDate,
                    )) ...[
                      DailyCaSourceLinkRow(link: link, compact: compact),
                      SizedBox(height: compact ? 4 : 6),
                    ],
                  ] else
                    SizedBox(height: gap),
                  SizedBox(
                    height: compact ? 42 : 46,
                    child: FilledButton.icon(
                      onPressed: widget.launching
                          ? null
                          : !allowed
                          ? null
                          : widget.questionsReady
                          ? (widget.paperCompleted
                                ? widget.onRevisePaper
                                : widget.onStartPaper)
                          : () {
                              showDailyCaUnavailableSheet(
                                context: context,
                                availableFrom: DailyCaSchedule.nextOpensAt(
                                  referenceIst: _ist,
                                ),
                                pendingLive: true,
                                onSeeHistory: () {},
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.45,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: widget.launching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Icon(
                              widget.paperCompleted
                                  ? Icons.replay_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                            ),
                      label: Text(
                        !allowed
                            ? 'Not started yet'
                            : !widget.questionsReady
                            ? 'Available soon'
                            : widget.paperCompleted
                            ? 'Revise this test'
                            : 'Start today\'s test',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (widget.paperCompleted &&
                      widget.onViewResults != null) ...[
                    SizedBox(height: compact ? 2 : 4),
                    TextButton(
                      onPressed: widget.launching
                          ? null
                          : widget.onViewResults,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View results',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  if (widget.paperCompleted &&
                      widget.onViewRankings != null) ...[
                    SizedBox(height: compact ? 2 : 4),
                    TextButton(
                      onPressed: widget.launching
                          ? null
                          : widget.onViewRankings,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Paper ranks',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: compact ? 8 : 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nextCopy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: infoSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          countdownLabel,
                          style: AppTextStyles.caption().copyWith(
                            color: info,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
