import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/fomo_pulse_cloud_service.dart';
import '../domain/fomo_pulse_models.dart';

final fomoPulseCloudServiceProvider = Provider<FomoPulseCloudService>(
  (ref) => FomoPulseCloudService(),
);

final fomoPulseRepositoryProvider = Provider<FomoPulseRepository>(
  (ref) => FomoPulseRepository(),
);

final fomoPulsePushServiceProvider = Provider<FomoPulsePushService>(
  (ref) => FomoPulsePushService(
    cloud: ref.watch(fomoPulseCloudServiceProvider),
  ),
);

typedef FomoPulseDetailData =
    ({FomoPulse pulse, FomoPulseAttemptState? attempt});

final fomoPulseHistoryProvider =
    AsyncNotifierProvider.autoDispose<
      FomoPulseHistoryNotifier,
      FomoPulseHistoryData
    >(FomoPulseHistoryNotifier.new);

final fomoPulseDetailProvider = AsyncNotifierProvider.autoDispose
    .family<FomoPulseDetailNotifier, FomoPulseDetailData, String>(
      FomoPulseDetailNotifier.new,
    );

class FomoPulseHistoryNotifier extends AsyncNotifier<FomoPulseHistoryData> {
  @override
  Future<FomoPulseHistoryData> build() async {
    final repo = ref.read(fomoPulseRepositoryProvider);
    return repo.loadHistory(
      onStale: (cached) {
        Future.microtask(() {
          if (ref.mounted) state = AsyncData(cached);
        });
      },
    );
  }

  Future<void> refresh({bool force = false}) async {
    final repo = ref.read(fomoPulseRepositoryProvider);
    final previous = state.value;
    if (!force &&
        previous != null &&
        await repo.isHistoryRecentlySynced()) {
      return;
    }
    try {
      final fresh = await repo.refreshHistory(mergeAttemptsFrom: previous);
      if (ref.mounted) state = AsyncData(fresh);
    } catch (e, st) {
      if (previous != null) return;
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}

class FomoPulseDetailNotifier extends AsyncNotifier<FomoPulseDetailData> {
  FomoPulseDetailNotifier(this.pulseId);

  final String pulseId;

  @override
  Future<FomoPulseDetailData> build() async {
    final repo = ref.read(fomoPulseRepositoryProvider);
    return repo.loadPulse(
      pulseId,
      onStale: (cached) {
        Future.microtask(() {
          if (ref.mounted) state = AsyncData(cached);
        });
      },
    );
  }
}
