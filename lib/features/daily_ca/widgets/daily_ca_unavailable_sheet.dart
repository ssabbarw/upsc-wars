import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../domain/daily_ca_schedule.dart';

/// Explains the newspaper quiz when today's paper is not live yet.
Future<void> showDailyCaUnavailableSheet({
  required BuildContext context,
  DateTime? availableFrom,
  bool pendingLive = false,
  VoidCallback? onSeeHistory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DailyCaUnavailableSheet(
      availableFrom:
          availableFrom ??
          DailyCaSchedule.nextOpensAt(referenceIst: DailyCaSchedule.nowIst()),
      pendingLive: pendingLive,
      onSeeHistory: onSeeHistory,
    ),
  );
}

class _DailyCaUnavailableSheet extends StatefulWidget {
  const _DailyCaUnavailableSheet({
    required this.availableFrom,
    this.pendingLive = false,
    this.onSeeHistory,
  });

  final DateTime availableFrom;
  final bool pendingLive;
  final VoidCallback? onSeeHistory;

  @override
  State<_DailyCaUnavailableSheet> createState() =>
      _DailyCaUnavailableSheetState();
}

class _DailyCaUnavailableSheetState extends State<_DailyCaUnavailableSheet> {
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

  static String _hms(Duration remaining) =>
      DailyCaSchedule.formatCountdownHms(remaining);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final softBg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final testFrom = DailyCaSchedule.dateOnly(
      widget.availableFrom,
    ).subtract(const Duration(days: 1));
    final dateLabel = DateFormat('MMM d').format(testFrom);
    final remaining = widget.availableFrom.difference(_ist);
    final countdown = _hms(remaining);

    return DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          sheetBottomPadding(context),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
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
                    widget.pendingLive
                        ? 'Questions aren\'t live yet'
                        : 'Questions will be available soon',
                    style: AppTextStyles.h2().copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.pendingLive
                        ? 'This morning\'s paper was generated, but it has not '
                            'been published to the app yet. Pull home to refresh '
                            'in a minute.'
                        : 'Each paper is built from news articles. It tests how well '
                            'you read the previous day\'s news — yesterday\'s newspaper, '
                            'this morning\'s quiz.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!widget.pendingLive) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: softBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            color: accent,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Today's test will be from :\n",
                                    style: AppTextStyles.bodySm().copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                  TextSpan(
                                    text: dateLabel,
                                    style: AppTextStyles.h2().copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '\nTest available in $countdown',
                                    style: AppTextStyles.bodySm().copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (widget.onSeeHistory != null) ...[
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSeeHistory?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: scheme.onSurface,
                        side: BorderSide(color: scheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        'See past current affairs MCQs',
                        style: AppTextStyles.label().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      'Got it',
                      style: AppTextStyles.label().copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
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
