import '../domain/daily_ca_schedule.dart';

bool canAccessDailyCaReview({required bool isSuperUser}) => isSuperUser;

String dailyCaReviewDateForNow({
  DateTime? referenceIst,
  int generateHourIst = 20,
  int generateMinuteIst = 0,
}) {
  final now = referenceIst ?? DailyCaSchedule.nowIst();
  final day = DailyCaSchedule.dateOnly(now);
  final nowMins = now.hour * 60 + now.minute;
  final generateMins = generateHourIst * 60 + generateMinuteIst;
  // Packs generate at [generateHourIst]:[generateMinuteIst] IST.
  var target = nowMins >= generateMins
      ? day
      : day.subtract(const Duration(days: 1));
  if (DailyCaSchedule.isSaturday(target)) {
    target = target.subtract(const Duration(days: 1));
  }
  return DailyCaSchedule.formatIsoDate(target);
}
