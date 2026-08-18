import 'package:cloud_functions/cloud_functions.dart';

import '../../fomo_pulse/data/fomo_pulse_cloud_service.dart';
import '../domain/llm_admin_settings.dart';

class LlmAdminCloudService {
  LlmAdminCloudService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<LlmAdminSettings> getSettings() async {
    try {
      final callable = _functions.httpsCallable('getLlmAdminSettings');
      final result = await callable.call<Map<String, dynamic>>({});
      return LlmAdminSettings.fromMap(Map<String, dynamic>.from(result.data));
    } catch (e, st) {
      FomoPulseCloudService.logCallableError('getLlmAdminSettings', e, st);
      rethrow;
    }
  }

  Future<void> setSettings({
    String? shotsModel,
    String? caModel,
    String? shotsApiKey,
    String? caApiKey,
    bool clearShotsKey = false,
    bool clearCaKey = false,
  }) async {
    try {
      final callable = _functions.httpsCallable('setLlmAdminSettings');
      await callable.call<Map<String, dynamic>>({
        if (shotsModel != null && shotsModel.trim().isNotEmpty)
          'shots_model': shotsModel.trim(),
        if (caModel != null && caModel.trim().isNotEmpty)
          'ca_model': caModel.trim(),
        if (shotsApiKey != null && shotsApiKey.trim().isNotEmpty)
          'shots_api_key': shotsApiKey.trim(),
        if (caApiKey != null && caApiKey.trim().isNotEmpty)
          'ca_api_key': caApiKey.trim(),
        if (clearShotsKey) 'clear_shots_key': true,
        if (clearCaKey) 'clear_ca_key': true,
      });
    } catch (e, st) {
      FomoPulseCloudService.logCallableError('setLlmAdminSettings', e, st);
      rethrow;
    }
  }

  static String describeError(Object error) {
    return FomoPulseCloudService.describeCallableError(error);
  }
}
