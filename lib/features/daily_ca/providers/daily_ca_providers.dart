import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../data/daily_ca_repository.dart';
import '../domain/daily_ca_schedule.dart';

/// Earliest selectable daily CA date from Remote Config (`daily_ca_calendar_min_date`).
final dailyCaCalendarMinDateProvider = FutureProvider<DateTime>((ref) async {
  if (kIsWeb) return DailyCaSchedule.defaultCalendarMinDate;
  await ref.watch(killSwitchProvider.future);
  try {
    final raw = FirebaseRemoteConfig.instance
        .getString(dailyCaCalendarMinDateRemoteConfigKey)
        .trim();
    return DailyCaSchedule.parseCalendarMinDate(
      raw.isEmpty ? DailyCaSchedule.defaultCalendarMinDateIso : raw,
    );
  } on Object catch (_) {
    return DailyCaSchedule.defaultCalendarMinDate;
  }
});

final dailyCaRepositoryProvider = Provider<DailyCaRepository>((ref) {
  return DailyCaRepository(db: ref.watch(userDatabaseProvider));
});

class DailyCaMonthKey {
  const DailyCaMonthKey({required this.year, required this.month});

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is DailyCaMonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

final dailyCaCompletedDatesProvider =
    FutureProvider.autoDispose.family<Set<String>, DailyCaMonthKey>((
      ref,
      key,
    ) async {
      final db = ref.watch(userDatabaseProvider);
      return db.sessionsDao.getCompletedDailyCaDatesBetween(
        startInclusive: DailyCaSchedule.monthStartIso(key.year, key.month),
        endInclusive: DailyCaSchedule.monthEndIso(key.year, key.month),
      );
    });

final dailyCaDayCompletedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, isoDate) async {
      final db = ref.watch(userDatabaseProvider);
      return db.sessionsDao.hasCompletedDailyCa(isoDate);
    });
