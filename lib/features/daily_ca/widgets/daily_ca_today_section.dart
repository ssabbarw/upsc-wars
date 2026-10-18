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
import '../../../l10n/l10n.dart';

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
    this.paperOpen = true,
    this.questionsReady = true,
    this.compact = false,
  });

  final DateTime minDate;

  /// News date this paper is drawn from, whether or not it has opened.
  final DateTime paperDate;
  final bool paperCompleted;
  final bool launching;

  /// False before [paperDate]'s 6 AM opening — the quiz exists but is early.
  final bool paperOpen;

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
    final allowed = DailyCaSchedule.isOnOrAfterMinDate(
      paperDate,
      widget.minDate,
    );
    final isTodaysPaper = DailyCaSchedule.isTodaysPaper(
      paperDate,
      referenceIst: _ist,
    );
    final nextOpen = DailyCaSchedule.nextOpensAt(referenceIst: _ist);
    final countdownLabel = DailyCaSchedule.formatCountdownHms(
      DailyCaSchedule.timeUntilNextOpen(referenceIst: _ist),
    );
    final nextIsToday =
        DailyCaSchedule.dateOnly(nextOpen) == DailyCaSchedule.dateOnly(_ist);
    final nextCopy = nextIsToday
        ? context.l10n.dcaTodayOpens
        : context.l10n.dcaTomorrowOpens;

    /// Opened on schedule but the pipeline never produced it — the next real
    /// paper is tomorrow's, so there is nothing to wait out today.
    final missing = allowed && widget.paperOpen && !widget.questionsReady;
    final untilOpen = DailyCaSchedule.formatCountdownHms(
      DailyCaSchedule.opensAtForDate(paperDate).difference(_ist),
    );

    final String headline;
    if (!allowed) {
      headline = context.l10n.dcaStartFrom(
        DateFormat('d MMM yyyy').format(widget.minDate),
      );
    } else if (!widget.paperOpen) {
      headline = context.l10n.dcaGoesLive6;
    } else if (missing) {
      headline = context.l10n.dcaNoPaperToday;
    } else if (widget.paperCompleted) {
      headline = context.l10n.dcaQuizDone;
    } else if (isTodaysPaper) {
      headline = context.l10n.dcaCaFromYesterday;
    } else {
      headline = context.l10n.dcaTenFromPaper(
        DateFormat('d MMM').format(paperDate),
      );
    }

    final reviseCopy = isTodaysPaper
        ? context.l10n.dcaReviseYesterday
        : context.l10n.dcaReviseThisDay;

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
                      onPressed:
                          widget.launching || !allowed || !widget.questionsReady
                          ? null
                          : widget.paperCompleted
                          ? widget.onRevisePaper
                          : widget.onStartPaper,
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
                              !allowed || !widget.questionsReady
                                  ? Icons.schedule_rounded
                                  : widget.paperCompleted
                                  ? Icons.replay_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                            ),
                      label: Text(
                        !allowed
                            ? context.l10n.dcaNotStartedYet
                            : !widget.paperOpen
                            ? context.l10n.dcaLiveIn(untilOpen)
                            : missing
                            ? context.l10n.dcaNextTestIn(countdownLabel)
                            : widget.paperCompleted
                            ? context.l10n.dcaReviseThisTest
                            : context.l10n.dcaStartTodays,
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
                      onPressed: widget.launching ? null : widget.onViewResults,
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
                        context.l10n.dcaViewResults,
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
