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

final fomoPulseHistoryProvider =
    FutureProvider.autoDispose<FomoPulseHistoryData>((ref) async {
      final repo = ref.watch(fomoPulseRepositoryProvider);
      return repo.loadHistory();
    });

final fomoPulseDetailProvider = FutureProvider.autoDispose
    .family<({FomoPulse pulse, FomoPulseAttemptState? attempt}), String>(
  (ref, pulseId) async {
    final repo = ref.watch(fomoPulseRepositoryProvider);
    return repo.loadPulse(pulseId);
  },
);
