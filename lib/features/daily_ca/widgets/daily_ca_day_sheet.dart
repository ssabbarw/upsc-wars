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
        onStartTest: onStartTest,
      ),
    ),
  );
}

class _DailyCaDaySheet extends StatelessWidget {
  const _DailyCaDaySheet({
    required this.isoDate,
    required this.completed,
    required this.onStartTest,
  });

  final String isoDate;
  final bool completed;
  final VoidCallback onStartTest;

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
    final isYesterdaysNews =
        DailyCaSchedule.dateOnly(
          now,
        ).difference(DailyCaSchedule.dateOnly(date)).inDays ==
        1;
    final links = DailyCaSourceLinks.forDate(date);
    final reviseHeading = isYesterdaysNews
        ? "You can revise yesterday's current affairs from our recommended links."
        : 'You can revise this day\'s current affairs from our recommended links.';

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
                    'DAILY CURRENT AFFAIRS TEST',
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
                    'This test is based on current affairs from $newsLabel.',
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
                      onPressed: () {
                        Navigator.pop(context);
                        onStartTest();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        completed ? 'Revise this test' : 'Start the test',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
