import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../../daily_war/domain/daily_war_models.dart';
import '../../daily_war/providers/daily_war_providers.dart';
import '../domain/daily_streak_service.dart';
import 'daily_drill_provider.dart';

/// Everything the Today hub needs that is **not** derived from the clock.
///
/// Time-dependent pieces (War phase, hero selection, countdowns) are computed in
/// the widget from a locally ticked clock, matching the Daily War card — the
/// server-offset providers are cached and would otherwise go stale mid-session.
class TodayHubData {
  const TodayHubData({
    required this.warEnabled,
    required this.warDateId,
    required this.warDoc,
    required this.warSubmitted,
    required this.yesterdayWarDateId,
    required this.yesterdayWarDoc,
    required this.yesterdayWarSubmitted,
    required this.caEnabled,
    required this.paperDate,
    required this.paperCompleted,
    required this.staticAvailable,
    required this.staticSubject,
    required this.staticSubjectDisplay,
    required this.staticCompleted,
    required this.streak,
    required this.fullDaysThisWeek,
  });

  final bool warEnabled;
  final String warDateId;
  final DailyWarDoc? warDoc;
  final bool warSubmitted;

  final String yesterdayWarDateId;
  final DailyWarDoc? yesterdayWarDoc;
  final bool yesterdayWarSubmitted;

  final bool caEnabled;

  /// News date of the paper quiz to serve now, or null when none is open.
  final DateTime? paperDate;
  final bool paperCompleted;

  /// False until home activation completes — the drill stays out of the way.
  final bool staticAvailable;
  final String staticSubject;
  final String staticSubjectDisplay;
  final bool staticCompleted;

  final int streak;
  final int fullDaysThisWeek;

  String? get paperDateIso =>
      paperDate == null ? null : DailyCaSchedule.formatIsoDate(paperDate!);

  /// Last night's War before 6 AM; tonight's War the rest of the hub day.
  DailyWarDoc? hubWarDoc(DateTime istNow) =>
      istNow.hour < 6 ? yesterdayWarDoc : warDoc;

  bool hubWarSubmitted(DateTime istNow) =>
      istNow.hour < 6 ? yesterdayWarSubmitted : warSubmitted;

  String hubWarDateId(DateTime istNow) =>
      istNow.hour < 6 ? yesterdayWarDateId : warDateId;

  List<DailyWarTopicRef> hubWarTopics(DateTime istNow) =>
      hubWarDoc(istNow)?.topics ?? const [];
}

/// Composes the three daily loops into one home surface.
final todayHubProvider = Provider.autoDispose<TodayHubData>((ref) {
  final warEnabled =
      ref.watch(dailyWarRemoteEnabledProvider).asData?.value ?? false;
  final warDoc = ref.watch(dailyWarTodayDocProvider).asData?.value;
  final warSubmission =
      ref.watch(dailyWarTodaySubmissionProvider).asData?.value;
  final yesterdayDoc = ref.watch(dailyWarYesterdayDocProvider).asData?.value;
  final yesterdaySubmission =
      ref.watch(dailyWarYesterdaySubmissionProvider).asData?.value;
  final warDateId = ref.watch(dailyWarTodayDateIdProvider);
  final yesterdayWarDateId = ref.watch(dailyWarYesterdayDateIdProvider);

  final caEnabled =
      ref.watch(dailyCaRemoteEnabledProvider).asData?.value ?? false;
  final minDate = ref.watch(dailyCaCalendarMinDateProvider).asData?.value;

  var paperDate = caEnabled ? DailyCaSchedule.paperQuizContentDate() : null;
  if (paperDate != null &&
      minDate != null &&
      !DailyCaSchedule.isOnOrAfterMinDate(paperDate, minDate)) {
    paperDate = null;
  }
  final paperIso =
      paperDate == null ? null : DailyCaSchedule.formatIsoDate(paperDate);
  final paperCompleted = paperIso == null
      ? false
      : ref.watch(dailyCaDayCompletedProvider(paperIso)).asData?.value ?? false;

  final drill = ref.watch(dailyDrillProvider).asData?.value;
  final prefs = ref.watch(prefsServiceProvider).asData?.value;

  return TodayHubData(
    warEnabled: warEnabled,
    warDateId: warDateId,
    warDoc: warDoc,
    warSubmitted: warSubmission != null,
    yesterdayWarDateId: yesterdayWarDateId,
    yesterdayWarDoc: yesterdayDoc,
    yesterdayWarSubmitted: yesterdaySubmission != null,
    caEnabled: caEnabled,
    paperDate: paperDate,
    paperCompleted: paperCompleted,
    staticAvailable: drill != null,
    staticSubject: drill?.subject ?? '',
    staticSubjectDisplay: drill?.subjectDisplayName ?? '',
    staticCompleted: drill?.completedToday ?? false,
    streak: prefs == null
        ? 0
        : DailyStreakService.visibleStreak(prefs: prefs),
    fullDaysThisWeek: prefs == null
        ? 0
        : DailyStreakService.fullDaysThisWeek(prefs: prefs),
  );
});
