import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';

/// Best-effort cache of the last few Daily CA papers for the first-run demo.
Future<void> prefetchDemoCurrentAffairs(WidgetRef ref) async {
  try {
    final repo = ref.read(dailyCaRepositoryProvider);
    for (final day in DailyCaSchedule.recentTestContentDates()) {
      try {
        await repo.ensureCachedForDate(DailyCaSchedule.formatIsoDate(day));
      } on Object {
        // Missing papers (Sunday gap, unpublished day) are fine.
      }
    }
  } on Object {
    // Offline / Firebase not ready — demo falls back to the bundled bank.
  }
}
