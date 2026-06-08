import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_database_provider.dart';
import '../data/daily_ca_repository.dart';
import '../domain/daily_ca_schedule.dart';

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
