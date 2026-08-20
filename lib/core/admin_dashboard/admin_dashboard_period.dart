/// Time windows shown on the admin dashboard.
enum AdminDashboardPeriod {
  day('Today', 1),
  week('7 days', 7),
  month('30 days', 30),
  threeMonths('3 months', 90),
  sixMonths('6 months', 180);

  const AdminDashboardPeriod(this.label, this.days);

  final String label;
  final int days;
}

const Duration adminDashboardIstOffset = Duration(hours: 5, minutes: 30);

/// Inclusive calendar-day keys `YYYY-MM-DD` ending today (local time).
List<String> adminDashboardDateKeysForPeriod(AdminDashboardPeriod period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return List<String>.generate(period.days, (i) {
    final d = today.subtract(Duration(days: period.days - 1 - i));
    return adminDashboardDateKey(d);
  });
}

/// Inclusive IST calendar-day keys ending today. Matches Cloud Functions `istParts().iso`.
List<String> adminDashboardIstDateKeysForPeriod(
  AdminDashboardPeriod period, {
  DateTime? nowUtc,
}) {
  final utc = nowUtc ?? DateTime.now().toUtc();
  final shifted = utc.add(adminDashboardIstOffset);
  final today = DateTime.utc(shifted.year, shifted.month, shifted.day);
  return List<String>.generate(period.days, (i) {
    final d = today.subtract(Duration(days: period.days - 1 - i));
    return adminDashboardDateKey(d);
  });
}

String adminDashboardTodayKey() => adminDashboardDateKey(DateTime.now());

String adminDashboardDateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
