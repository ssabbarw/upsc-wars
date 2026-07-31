import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_clock_provider.g.dart';

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
  final offsetAsync = ref.watch(serverTimeOffsetMsProvider);
  final offset = offsetAsync.asData?.value ?? 0;
  return DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch + offset,
    isUtc: true,
  );
}
