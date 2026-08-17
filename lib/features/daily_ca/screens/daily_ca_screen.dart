import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';
import '../domain/open_daily_ca_test.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_month_calendar.dart';
import '../widgets/daily_ca_today_section.dart';

class DailyCaScreen extends HookConsumerWidget {
  const DailyCaScreen({super.key, this.autoStartPaper = false});

  /// Set from the morning notification tap so it lands on the quiz itself.
  final bool autoStartPaper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final minDate = ref.watch(dailyCaCalendarMinDateProvider).maybeWhen(
      data: (date) => date,
      orElse: () => DailyCaSchedule.defaultCalendarMinDate,
    );
    final minMonth = DailyCaSchedule.minMonthForDate(minDate);
    final istNow = DailyCaSchedule.nowIst();
    final paperDate = DailyCaSchedule.paperQuizContentDate(referenceIst: istNow);
    final paperIso =
        paperDate == null ? null : DailyCaSchedule.formatIsoDate(paperDate);
    final paperLiveAsync = ref.watch(dailyCaScheduledPaperIsLiveProvider);
    final paperLive = paperLiveAsync.asData?.value ?? false;
    final paperChecking = paperLiveAsync.isLoading;
    final initialMonth = DateTime(istNow.year, istNow.month);
    final displayedMonth = useState(
      initialMonth.isBefore(minMonth) ? minMonth : initialMonth,
    );
    final monthKey = DailyCaMonthKey(
      year: displayedMonth.value.year,
      month: displayedMonth.value.month,
    );
    final completedAsync = ref.watch(dailyCaCompletedDatesProvider(monthKey));
    final launching = useState(false);

    final paperCompleted = paperIso != null &&
        completedAsync.maybeWhen(
          data: (dates) => dates.contains(paperIso),
          orElse: () => false,
        );

    Future<void> openDayTest(String isoDate, {required bool isRevise}) async {
      if (launching.value) return;
      launching.value = true;
      try {
        await openDailyCaTest(
          context: context,
          ref: ref,
          isoDate: isoDate,
          isRevise: isRevise,
          onFinished: () =>
              ref.invalidate(dailyCaCompletedDatesProvider(monthKey)),
        );
      } finally {
        launching.value = false;
      }
    }

    final openDayTestStable = useCallback(
      openDayTest,
      [monthKey, paperCompleted],
    );

    final autoStarted = useRef(false);
    useEffect(() {
      if (!autoStartPaper || autoStarted.value || paperIso == null) return null;
      if (paperChecking) return null;
      autoStarted.value = true;
      if (!paperLive) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(openDayTestStable(paperIso, isRevise: paperCompleted));
      });
      return null;
    }, [autoStartPaper, paperIso, paperLive, paperChecking]);

    void shiftMonth(int delta) {
      final m = displayedMonth.value;
      final next = DateTime(m.year, m.month + delta);
      if (delta < 0 &&
          DailyCaSchedule.isMonthBefore(next.year, next.month, minMonth)) {
        return;
      }
      displayedMonth.value = next;
    }

    final canGoToPreviousMonth = !DailyCaSchedule.isMonthBefore(
      displayedMonth.value.year,
      displayedMonth.value.month - 1,
      minMonth,
    );
    final monthTitle = DateFormat('MMMM yyyy').format(displayedMonth.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Current Affairs')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DailyCaTodaySection(
            minDate: minDate,
            paperDate: paperDate,
            paperCompleted: paperCompleted,
            launching: launching.value || paperChecking,
            questionsReady: paperLive,
            onStartPaper: paperIso == null || !paperLive
                ? null
                : () => unawaited(
                      openDayTestStable(paperIso, isRevise: paperCompleted),
                    ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              IconButton(
                onPressed: canGoToPreviousMonth ? () => shiftMonth(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
              ),
              IconButton(
                onPressed: () => shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          completedAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(
              'Could not load progress: $e',
              style: AppTextStyles.bodySm().copyWith(color: AppColors.wrong),
            ),
            data: (completed) => DailyCaMonthCalendar(
              year: displayedMonth.value.year,
              month: displayedMonth.value.month,
              completedDates: completed,
              minDate: minDate,
              onDateTap: (iso) {
                if (launching.value) return;
                final date = DailyCaSchedule.parseIsoDate(iso);
                if (!DailyCaSchedule.isOnOrAfterMinDate(date, minDate)) {
                  return;
                }
                final now = DailyCaSchedule.nowIst();
                if (!DailyCaSchedule.isPublishedForDate(
                  date,
                  referenceIst: now,
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This test is not available yet.',
                        style: AppTextStyles.bodySm(),
                      ),
                    ),
                  );
                  return;
                }
                unawaited(
                  openDayTestStable(iso, isRevise: completed.contains(iso)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
