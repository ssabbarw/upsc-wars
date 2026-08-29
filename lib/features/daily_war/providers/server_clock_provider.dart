import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/super_user_provider.dart';
import '../domain/daily_war_schedule.dart';

part 'server_clock_provider.g.dart';

/// Super-user only. In-memory (clears on process kill). Does not persist.
enum DailyWarDebugClock {
  off,

  /// Pretend it is 9:05 PM IST today (live late-join window).
  liveJoinable,
}

class DailyWarDebugClockController extends Notifier<DailyWarDebugClock> {
  @override
  DailyWarDebugClock build() {
    ref.listen<bool>(isSuperUserProvider, (previous, next) {
      if (!next) state = DailyWarDebugClock.off;
    });
    return DailyWarDebugClock.off;
  }

  void set(DailyWarDebugClock value) => state = value;
}

final dailyWarDebugClockProvider =
    NotifierProvider<DailyWarDebugClockController, DailyWarDebugClock>(
      DailyWarDebugClockController.new,
    );

/// When [DailyWarDebugClock.liveJoinable] is on, ignores Firebase offset and
/// aims the wall clock at 21:05 IST today.
int effectiveServerTimeOffsetMs(
  DailyWarDebugClock debug,
  int realOffsetMs,
) {
  if (debug == DailyWarDebugClock.liveJoinable) {
    return DailyWarSchedule.offsetMsUntilIstWall(hour: 21, minute: 5);
  }
  return realOffsetMs;
}

/// Offset in ms: `serverNow ≈ DateTime.now().millisecondsSinceEpoch + offset`.
///
/// Backed by Firebase RTDB `.info/serverTimeOffset`. Falls back to `0` (device
/// clock) when unavailable (web without RTDB, offline cold start).
@Riverpod(keepAlive: true)
Stream<int> serverTimeOffsetMs(Ref ref) async* {
  if (kIsWeb) {
    yield 0;
    return;
  }
  try {
    final refDb = FirebaseDatabase.instance.ref('.info/serverTimeOffset');
    await for (final event in refDb.onValue) {
      final v = event.snapshot.value;
      if (v is num) {
        yield v.toInt();
      } else {
        yield 0;
      }
    }
  } on Object catch (_) {
    yield 0;
  }
}

/// Corrected "now" as UTC [DateTime], refreshing when the offset stream updates.
@Riverpod(keepAlive: true)
DateTime serverNowUtc(Ref ref) {
  final offset = effectiveServerTimeOffsetMs(
    ref.watch(dailyWarDebugClockProvider),
    ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0,
  );
  return DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch + offset,
    isUtc: true,
  );
}
