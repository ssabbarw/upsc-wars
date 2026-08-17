import '../domain/daily_ca_schedule.dart';

bool canAccessDailyCaReview({required bool isSuperUser}) => isSuperUser;

String dailyCaReviewDateForNow({DateTime? referenceIst}) {
  final now = referenceIst ?? DailyCaSchedule.nowIst();
  final day = DailyCaSchedule.dateOnly(now);
  // Packs generate at 8 PM IST. Before that, yesterday's draft is the one to review.
  var target = now.hour >= 20 ? day : day.subtract(const Duration(days: 1));
  if (DailyCaSchedule.isSaturday(target)) {
    target = target.subtract(const Duration(days: 1));
  }
  return DailyCaSchedule.formatIsoDate(target);
}
