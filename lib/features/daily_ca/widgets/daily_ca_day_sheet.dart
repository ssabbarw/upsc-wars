import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../domain/daily_ca_schedule.dart';
import '../domain/daily_ca_source_links.dart';
import 'daily_ca_source_link_row.dart';

/// Date hub before starting a Daily CA paper: news date, source briefs, start.
Future<void> showDailyCaDaySheet({
  required BuildContext context,
  required String isoDate,
  required bool completed,
  required VoidCallback onStartTest,
  bool questionsReady = true,
  VoidCallback? onViewRankings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: _DailyCaDaySheet(
        isoDate: isoDate,
        completed: completed,
        questionsReady: questionsReady,
        onStartTest: onStartTest,
        onViewRankings: onViewRankings,
      ),
    ),
  );
}

class _DailyCaDaySheet extends StatelessWidget {
  const _DailyCaDaySheet({
    required this.isoDate,
    required this.completed,
    required this.questionsReady,
    required this.onStartTest,
    this.onViewRankings,
  });

  final String isoDate;
  final bool completed;
  final bool questionsReady;
  final VoidCallback onStartTest;
  final VoidCallback? onViewRankings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final softBg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final date = DailyCaSchedule.parseIsoDate(isoDate);
    final dateLabel = DateFormat('d MMMM yyyy').format(date);
    final newsLabel = DateFormat('d MMMM').format(date);
    final now = DailyCaSchedule.nowIst();
    final openPaper = DailyCaSchedule.paperQuizContentDate(referenceIst: now);
    final isOpenPaper =
        openPaper != null &&
        DailyCaSchedule.dateOnly(openPaper) == DailyCaSchedule.dateOnly(date);
    final isTodaysPaper = DailyCaSchedule.isTodaysPaper(
      date,
      referenceIst: now,
    );
    final links = DailyCaSourceLinks.forDate(date);
    final reviseHeading = isTodaysPaper
        ? "You can revise yesterday's current affairs from our recommended links."
        : 'You can revise this day\'s current affairs from our recommended links.';
    final ctaLabel = !questionsReady
        ? 'Available soon'
        : completed
        ? 'Revise this test'
        : isOpenPaper
        ? 'Start today\'s test'
        : 'Start the test';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        sheetBottomPadding(context, base: AppSpacing.sm),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isOpenPaper
                        ? 'TODAY\'S PAPER'
                        : 'DAILY CURRENT AFFAIRS TEST',
                    style: AppTextStyles.caption().copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dateLabel,
                    style: AppTextStyles.h1().copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This test is from questions from $newsLabel.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: accent.withValues(alpha: 0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          reviseHeading,
                          style: AppTextStyles.label().copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'These are our favourite sources for this day\'s current affairs.',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < links.length; i++) ...[
                          if (i > 0) const SizedBox(height: 4),
                          DailyCaSourceLinkRow(link: links[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: !questionsReady
                          ? null
                          : () {
                              Navigator.pop(context);
                              onStartTest();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.45,
                        ),
                        disabledForegroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        ctaLabel,
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (onViewRankings != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onViewRankings!();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: Text(
                          'Paper ranks',
                          style: AppTextStyles.label().copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
